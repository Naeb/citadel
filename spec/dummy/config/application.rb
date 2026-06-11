# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
    config.active_support.isolation_level = :fiber
    config.eager_load = false
    config.consider_all_requests_local = true
    config.api_only = true
    config.secret_key_base = "test_secret_key_base_for_dummy_app_only"
  end
end
