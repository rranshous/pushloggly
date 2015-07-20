require_relative 'container_info'

class LogPrinter
  def initialize container_id
    @container_name = ContainerInfo.name(container_id)
  end
  def call type, timestamp, message
    STDOUT.puts "#{@container_name} [#{type}] @ #{timestamp} | #{message}\n"
  end
end

