# frozen_string_literal: true

require "rack"

module Citadel
  module Gatekeepers
    class Generic
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        realm = resolve_realm(request)
        Citadel::Realm.enter(realm) { @app.call(env) }
      end

      private

      def resolve_realm(request)
        realm = parse_realm(request)
        realm = Citadel.config.default_realm if realm.nil? || realm.empty?
        validate_realm!(realm)
        realm
      end

      def validate_realm!(realm)
        Adapters::PostgresqlSchemaAdapter.validate_name!(realm)
      end

      def parse_realm(_request)
        raise NotImplementedError, "#{self.class} must implement #parse_realm"
      end
    end
  end
end
