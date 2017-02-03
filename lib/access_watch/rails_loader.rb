module AccessWacth
  class RailsLoader
    def self.start
      return if !defined?(Rails)
      Rails::Railtie.initializer "access_watch.detect_config_file" do
        if (path = Rails.root.join("config/access_watch.yml")).exist?
          if config = AccessWacth::RailsLoader.load_config_file(path)[Rails.env]
            Rails.application.config.middleware.use(AccessWatch::RackLogger, config.symbolize_keys)
          end
        end
      end
    end

    def self.load_config_file(path)
      YAML.load(ERB.new(path.read).result)
    end
  end
end
