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

