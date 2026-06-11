# frozen_string_literal: true

Citadel.configure do |config|
  config.isolation = :schema
  config.default_realm = "public"
  config.persistent_schemas = []
  config.realms = -> { %w[gondor rohan] }
  config.gatekeeper = nil
  config.migrate_all_realms = false
end
