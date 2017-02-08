module AccessWacth
  class RailsLoader
    @started = false

    def self.start_on_rails_initialization
      return if !defined?(Rails)
      Rails::Railtie.initializer "access_watch.detect_config_file" do
        AccessWacth::RailsLoader.start
      end
    end

    def self.start
      return if @started
      if (path = Rails.root.join("config/access_watch.yml")).exist?
        if config = AccessWacth::RailsLoader.load_config_file(path)[Rails.env]
          Rails.application.config.middleware.use(AccessWatch::RackLogger, config.symbolize_keys)
          @started = true
        end
      end
    end

    def self.load_config_file(path)
      YAML.load(ERB.new(path.read).result)
    end
  end
end
