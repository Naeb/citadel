# frozen_string_literal: true

require "active_support"
require "citadel"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Citadel::Presence.reset
    Citadel.instance_variable_set(:@config, Citadel::Config.new)
  end
end
