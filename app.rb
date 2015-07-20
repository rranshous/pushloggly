# listen to the stdout / stderr stream of all containers
# including containers which are started after this script
# pushlish interlaced log to the screen
# pushblish to loggly
# log messages should include container names, std or stderr, timestamp + message

class HTTPSocketLogStream < UNIXSocket
  def initialize container_id
    @container_id = container_id
    super socket_path
    send_headers
    ignore_response_headers
  end

  private

  def send_headers
    write "#{method} #{path}?#{query_string} #{http_version}"
    write "\n\n"
  end

  def ignore_response_headers
    while line = gets
      break if line == "\r\n"
    end
  end

  def method
    "GET"
  end

  def path
    "/containers/#{@container_id}/logs"
  end

  def query_string
    "stderr=1&stdout=1&timestamps=1&follow=1&tail=0"
  end

  def http_version
    "HTTP/1.1"
  end

  def socket_path
    "/var/run/docker.sock"
  end
end

require 'excon'
class DockerHTTPLogDecoder
  def initialize data_stream
    @data_stream = data_stream
  end

  def enumerate
    Enumerator.new do |yielder|
      docker_chunk_size = nil
      docker_stream_type = nil
      loop do
        raw_http_chunk_size = @data_stream.gets
        if raw_http_chunk_size.nil?
          return true
        end
        http_chunk_size = raw_http_chunk_size.strip.to_i
        docker_read = false
        if docker_chunk_size && docker_chunk_size != 0
          if docker_chunk_size == 0
            sleep 0.1
            next
          end
          http_chunk_body = @data_stream.read(docker_chunk_size.to_i)
          docker_read = true
          docker_chunk_size = nil
        else
          http_chunk_body = @data_stream.read(http_chunk_size)
        end
        @data_stream.read(2)
        if docker_read
          stream_type = case docker_stream_type
                        when 0
                          :STDIN
                        when 1
                          :STDOUT
                        when 2
                          :STDERR
                        end
          timestamp, message = http_chunk_body.split(' ', 2)
          yielder << [stream_type, timestamp, message.strip]
        end
        if http_chunk_size == 8
          docker_stream_type, docker_chunk_size = http_chunk_body.unpack("CxxxN")
        end
      end
    end
  end
end

class HTTPSocketLogReader
  def initialize container_id
    @container_id = container_id
    @stream = nil
  end

  def enumerate
    @stream = HTTPSocketLogStream.new @container_id
    decoder = DockerHTTPLogDecoder.new @stream
    decoder.enumerate
  end
end

class LogPrinter
  def initialize container_id
    @container_name = ContainerInfo.name(container_id)
  end
  def call type, timestamp, message
    puts "#{@container_name}[#{type}] @ #{timestamp} | #{message}"
  end
end

require 'httparty'
require 'persistent_httparty'
require 'json'
class LogglyPusher
  include HTTParty
  persistent_connection_adapter({ :pool_size => 10,
                                  :idle_timeout => 10,
                                  :keep_alive => 30 })
  def initialize container_id
    @container_name = ContainerInfo.name(container_id)
    @container_id = container_id
  end

  def call type, timestamp, message
    to_send = format_message(type, timestamp, message)
    r = self.class.post("http://logs-01.loggly.com/inputs/#{token}/tag/http/",
                        body: to_send, headers: { 'Content-Type' => 'text/plain' })
    raise "BAD RESPONSE: #{r.code}:: #{r.body}" if r.code != 200
  end

  private

  def format_message type, timestamp, message
    "#{timestamp} #{message} "+
    {
      timestamp: timestamp,
      source: type,
      container_name: @container_name,
      container_id: @container_id,
      message: message,
    }.to_json
  end

  def token
    "513ba235-db85-43aa-8ce6-cd5104e50a46"
  end
end

require 'thread'
class ThreadedLogHandler < Thread
  def initialize *args
    super do |container_id, *handlers|
      logs = HTTPSocketLogReader.new container_id
      logs.enumerate.each do |type, timestamp, message|
        handlers.each { |h| h.call type, timestamp, message }
      end
    end
  end
end

require 'docker'
class ContainerInfo
  def self.image_name container_id
    ::Docker::Container.get(container_id).json['Config']['Image']
  end
  def self.name container_id
    ::Docker::Container.get(container_id).json['Name']
  end
end

class ThreadedContainerWatcher < Thread
  def initialize
    self.class.watch_existing
    super do
      begin
        ::Docker::Event.stream do |event|
          if event.status == 'create'
            self.class.watch_container event.id
          end
        end
      rescue Excon::Errors::SocketError
        retry
      end
    end
  end

  def self.watch_existing
    Docker::Container.all.each do |container|
      watch_container container.id
    end
  end

  def self.watch_container container_id
    log_printer = LogPrinter.new container_id
    loggly_pusher = LogglyPusher.new container_id
    ThreadedLogHandler.new(container_id, log_printer, loggly_pusher)
  end
end

Thread.abort_on_exception = true
ThreadedContainerWatcher.new.join
