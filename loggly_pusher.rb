require 'httparty'
require 'persistent_httparty'
require 'json'
require_relative 'json_finder'
require_relative 'container_info'
class LogglyPusher
  include HTTParty
  persistent_connection_adapter({ :pool_size => 10,
                                  :idle_timeout => 10,
                                  :keep_alive => 30 })
  def initialize container_id
    @container_image = ContainerInfo.image_name(container_id)
    @container_name = ContainerInfo.name(container_id)
    @container_env = ContainerInfo.env(container_id)
    @container_app_name = ContainerInfo.app_name(container_id)
    @container_id = container_id
  end

  def call type, timestamp, message
    to_send = formatted_message(type, timestamp, message)
    context = message_context(type, timestamp, message)
    to_send = with_context to_send, context
    headers = { 'Content-Type' => 'text/plain' }
    tags_string = tags(type).join(',')
    r = self.class.post("http://logs-01.loggly.com/inputs/#{@@token}/tag/#{tags_string}/",
                        body: to_send, headers: headers)
    raise "BAD RESPONSE: #{r.code}:: #{r.body}" if r.code != 200
  end

  def self.set_token token
    @@token = token
  end

  private

  def tags type
    tags = ['http',
            "stream.#{type}"]
    if @container_app_name
      tags += ["app_name.#{@container_app_name}"]
    end
    tags
  end

  def formatted_message type, timestamp, message
    message.strip
  end

  def message_context type, timestamp, message
    {
      'timestamp' => timestamp,
      'stream' => type.to_s,
      'container_name' => @container_name,
      'container_id' => @container_id,
      'container_image' => @container_image,
      'env' => @container_env
    }
  end

  def with_context message, context_data
    json_string = JSONFinder.find_in message
    if json_string
      message.gsub json_string, context_data.merge(JSON.parse(json_string)).to_json
    else
      "#{message} #{context_data.to_json}"
    end
  end
end

