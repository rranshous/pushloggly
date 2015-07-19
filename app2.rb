require 'pry'
path = "/containers/760a020c0e9c/logs?stderr=1&stdout=1&timestamps=1&follow=1"
uri = URI('unit:///var/run/docker.sock' + path)
binding.pry

Net::HTTP.start(uri.host, uri.port) do |http|
  request = Net::HTTP::Get.new uri

  http.request request do |response|
    response.read_body do |chunk|
      io.write chunk
    end
  end
end
