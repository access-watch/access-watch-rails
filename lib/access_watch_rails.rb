module AccessWatch
end

require "access_watch"
require "access_watch/logger"
require "access_watch/rack_logger"
require "access_watch/rails_version"

if defined?(Rails)
  require "access_watch/rails_loader"
  AccessWacth::RailsLoader.start
end
