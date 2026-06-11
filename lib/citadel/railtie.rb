# frozen_string_literal: true

return unless defined?(Rails::Railtie)

module Citadel
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/citadel.rake", __dir__)
    end

    config.before_configuration do
      require "citadel"
    end

    initializer "citadel.activate", after: :load_config_initializers do
      Citadel.activate!
    end

    initializer "citadel.middleware", after: "citadel.activate" do |app|
      gatekeeper = Citadel.config.gatekeeper
      next if gatekeeper.nil?

      middleware = gatekeeper_class_for(gatekeeper)
      app.config.middleware.insert_after ActionDispatch::Callbacks, middleware
    end

    initializer "citadel.enhance_db_migrate", after: "citadel.activate" do
      next unless Citadel.config.migrate_all_realms

      ActiveSupport.on_load(:active_record) do
        next unless Rake::Task.task_defined?("db:migrate")

        Rake::Task["db:migrate"].enhance do
          Rake::Task["citadel:migrate"].invoke
        end
      end
    end

    def self.gatekeeper_class_for(gatekeeper)
      case gatekeeper
      when :subdomain
        Gatekeepers::Subdomain
      when Class
        gatekeeper
      when String, Symbol
        Gatekeepers.const_get(gatekeeper.to_s.camelize)
      else
        raise Citadel::ConfigurationError, "unsupported gatekeeper: #{gatekeeper.inspect}"
      end
    end
  end
end
