require_relative 'threaded_log_handler'
class ThreadedContainerWatcher < Thread
  def initialize *args
    super do |handlers|
      @handlers = handlers
      watch_existing
      begin
        ::Docker::Event.stream do |event|
          if event.status == 'create'
            self.watch_container event.id
          end
        end
      rescue Excon::Errors::SocketError
        retry
      end
    end
  end

  def watch_existing
    Docker::Container.all.each do |container|
      watch_container container.id
    end
  end

  def watch_container container_id
    handlers = @handlers.map { |h| h.new container_id }
    ThreadedLogHandler.new(container_id, *handlers)
  end
end

