require_relative 'http_socket_log_stream'
require_relative 'docker_http_log_decoder'
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

