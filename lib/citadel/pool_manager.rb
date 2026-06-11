# frozen_string_literal: true

require "concurrent/map"

module Citadel
  class PoolManager
    class << self
      def pool_for(realm, role: ActiveRecord::Base.current_role)
        key = pool_key(realm, role)
        pools.compute_if_absent(key) { build_pool(realm, role) }
      end

      def clear!
        pools.each_value do |pool|
          pool.disconnect! if pool.respond_to?(:disconnect!)
        end
        pools.clear
        handlers.clear
      end

      private

      def pools
        @pools ||= Concurrent::Map.new
      end

      def handlers
        @handlers ||= Concurrent::Map.new
      end

      def pool_key(realm, role)
        "#{realm}:#{role}"
      end

      def build_pool(realm, role)
        handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        handler.establish_connection(
          pool_config_for(realm, role),
          owner_name: ActiveRecord::Base,
          role: role,
          shard: shard_key(realm)
        )
        handlers[pool_key(realm, role)] = handler
        handler.connection_pool_list(role: role, shard: shard_key(realm)).first
      end

      def shard_key(realm)
        :"citadel_#{realm}"
      end

      def pool_config_for(realm, role)
        base = ActiveRecord::Base.connection_db_config
        configuration = base.configuration_hash.dup
        configuration[:schema_search_path] = adapter.schema_search_path_for(realm)
        configuration[:citadel_realm] = realm.to_s

        ActiveRecord::DatabaseConfigurations::HashConfig.new(
          base.env_name,
          "citadel_#{realm}_#{role}",
          configuration
        )
      end

      def adapter
        @adapter ||= Adapters::PostgresqlSchemaAdapter.new
      end
    end
  end
end
