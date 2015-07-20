require_relative 'http_socket_log_reader'
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

