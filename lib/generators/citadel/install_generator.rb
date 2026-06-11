# frozen_string_literal: true

require "rails/generators/base"

module Citadel
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    desc "Install Citadel initializer and configure fiber isolation"

    def copy_initializer
      template "initializer.rb.tt", "config/initializers/citadel.rb"
    end

    def configure_fiber_isolation
      inject_into_file "config/application.rb", after: "class Application < Rails::Application\n" do
        <<~RUBY

          # Required for fiber-safe realm switching via Citadel::Presence
          config.active_support.isolation_level = :fiber
        RUBY
      end
    end
  end
end
