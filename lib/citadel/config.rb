# frozen_string_literal: true

module Citadel
  class Config
    attr_accessor :isolation,
                  :default_realm,
                  :persistent_schemas,
                  :realms,
                  :gatekeeper,
                  :migrate_all_realms

    def initialize
      @foundation_models = []
      @persistent_schemas = []
      @migrate_all_realms = true
      @frozen = false
    end

    def foundation_models
      @foundation_models.dup
    end

    def configure
      raise ConfigurationError, "configuration is frozen" if @frozen

      yield self if block_given?
      self
    end

    def register_foundation_model(model)
      name = model.is_a?(String) ? model : model.name
      @foundation_models << name unless @foundation_models.include?(name)
    end

    def foundation_model?(klass)
      @foundation_models.include?(klass.name)
    end

    def apply_defaults!
      @isolation ||= :schema
      @default_realm ||= "public"
      @gatekeeper ||= nil
      @realms ||= -> { [] }
      @persistent_schemas ||= []
    end

    def validate!
      raise ConfigurationError, "isolation must be :schema" unless isolation == :schema
      raise ConfigurationError, "realms must respond to #call" unless realms.respond_to?(:call)
      raise ConfigurationError, "default_realm is required" if default_realm.to_s.empty?

      Adapters::PostgresqlSchemaAdapter.validate_name!(default_realm)
      persistent_schemas.each { |schema| Adapters::PostgresqlSchemaAdapter.validate_name!(schema) }
    end

    def freeze!
      @frozen = true
      freeze
    end

    def frozen?
      @frozen
    end
  end
end
