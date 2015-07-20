### strait sockets
# strait socket means you can use a select loop

require 'pry'

socket_path = "/var/run/docker.sock"
docker_socket = UNIXSocket.new socket_path
container_id = ARGV.shift
headers = <<-HEADERS
GET /containers/#{container_id}/logs?stderr=1&stdout=1&timestamps=1&follow=1 HTTP/1.1
HEADERS
docker_socket.write(headers)
docker_socket.write("\n\n")

# eat the HTTP header
while line = docker_socket.gets
  break if line == "\r\n"
end


docker_chunk_size = nil
loop do
  raw_http_chunk_size = docker_socket.gets
  if raw_http_chunk_size.nil?
    raise "CONTAINER DONE"
  end
  #puts "CHUNK SIZE RAW: #{raw_http_chunk_size}"
  http_chunk_size = raw_http_chunk_size.strip.to_i
  #puts "HTTP CHUNK SIZE: #{http_chunk_size}"
  docker_read = false
  if docker_chunk_size && docker_chunk_size != 0
    if docker_chunk_size == 0
      #puts "END OF LOG?"
      sleep 1
      next
    end
    #puts "using docker chunk size: #{docker_chunk_size.to_i} || #{docker_chunk_size}"
    http_chunk_body = docker_socket.read(docker_chunk_size.to_i)
    docker_read = true
    docker_chunk_size = nil
  else
    http_chunk_body = docker_socket.read(http_chunk_size)
  end
  docker_socket.read(2)
  #puts "HTTP CHUNK BODY: #{http_chunk_body[0..100]}<--BODY"
  if docker_read
    puts "LOG: #{http_chunk_body}"
  end
  if http_chunk_size == 8
    docker_stream_type, docker_chunk_size = http_chunk_body.unpack("CxxxN")
  end
  #puts "UNPACKED: #{docker_stream_type} :: #{docker_chunk_size}"
end



## excon http library
# easier to work with, def not as hacky

require 'excon'
container_id = ARGV.shift
path = "/containers/#{container_id}/logs"
socket_path = "/var/run/docker.sock"
query_args = { stderr: 1, stdout: 1, timestamps: 1, follow: 1 }
chunk_handler = lambda do |chunk, remaining_bytes, total_bytes|
  if chunk.length == 8
    #puts "#{chunk.unpack("CxxxN")}"
  else
    puts "#{chunk}"
  end
end
Excon.get('unix://'+path, socket:socket_path, query:query_args,
          response_block: chunk_handler)
puts "DONE"

