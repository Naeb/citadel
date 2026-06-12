# frozen_string_literal: true

require_relative "citadel/version"

module Citadel
  class Error < StandardError; end
  class RealmNotFound < Error; end

  class << self
    attr_writer :loader

    def configure(&)
      config.configure(&)
    end

    def config
      @config ||= Config.new
    end

    def activate!
      config.apply_defaults!
      config.validate!
      config.freeze!
      Patches::ConnectionHandling.apply!
    end

    def load_railtie!
      return if defined?(Citadel::Railtie)
      return unless defined?(Rails::Railtie)

      require "citadel/railtie"
    end

    def ensure_activated!
      activate! unless config.frozen?
    end
  end
end

require_relative "citadel/errors"
require_relative "citadel/loader"
Citadel.loader = Citadel::Loader.setup

Citadel.load_railtie!

if defined?(ActiveSupport::LazyLoadHooks)
  require "active_support/lazy_load_hooks"

  unless defined?(Citadel::Railtie)
    ActiveSupport.on_load(:before_configuration) do
      Citadel.load_railtie!
    end
  end

  ActiveSupport.on_load(:after_initialize) do
    Citadel.ensure_activated!
  end
end
