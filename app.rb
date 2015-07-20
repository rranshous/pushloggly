# listen to the stdout / stderr stream of all containers
# including containers which are started after this script
# pushlish interlaced log to the screen
# pushblish to loggly
# log messages should include container names, std or stderr, timestamp + message

require_relative 'log_printer'
require_relative 'loggly_pusher'
require_relative 'threaded_container_watcher'

Thread.abort_on_exception = true
LogglyPusher.set_token ARGV.shift || ENV['LOGGLY_TOKEN']
handlers = [ LogPrinter, LogglyPusher ]
ThreadedContainerWatcher.new(handlers).join
