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

