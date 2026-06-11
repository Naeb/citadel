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
  end
end

require_relative "citadel/errors"
require_relative "citadel/loader"
Citadel.loader = Citadel::Loader.setup

require "citadel/railtie" if defined?(Rails::Railtie)
