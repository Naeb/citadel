# frozen_string_literal: true

module Citadel
  module Adapters
    class PostgresqlSchemaAdapter < AbstractAdapter
      SCHEMA_NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/

      class << self
        def validate_name!(name)
          normalized = name.to_s
          return if normalized.match?(SCHEMA_NAME_PATTERN)

          raise InvalidSchemaNameError, "invalid schema name: #{name.inspect}"
        end

        def quote_schema(name)
          validate_name!(name)
          %("#{name}")
        end
      end

      def create_schema(name)
        self.class.validate_name!(name)
        connection.execute("CREATE SCHEMA IF NOT EXISTS #{self.class.quote_schema(name)}")
      end

      def drop_schema(name)
        self.class.validate_name!(name)
        connection.execute("DROP SCHEMA IF EXISTS #{self.class.quote_schema(name)} CASCADE")
      end

      def schema_exists?(name)
        self.class.validate_name!(name)
        result = connection.select_value(<<~SQL.squish)
          SELECT EXISTS(
            SELECT 1 FROM information_schema.schemata
            WHERE schema_name = #{connection.quote(name.to_s)}
          )
        SQL
        ActiveRecord::Type::Boolean.new.cast(result)
      end

      def schema_search_path_for(realm)
        self.class.validate_name!(realm)

        schemas = [realm.to_s]
        schemas.concat(Citadel.config.persistent_schemas.map(&:to_s))
        schemas << "public" unless realm.to_s == "public"
        schemas.uniq.join(", ")
      end

      def ensure_schema_migrations_table!(realm)
        self.class.validate_name!(realm)
        return if schema_migrations_table_exists?(realm)

        quoted_schema = self.class.quote_schema(realm)
        connection.execute(<<~SQL.squish)
          CREATE TABLE #{quoted_schema}.schema_migrations (
            version character varying NOT NULL PRIMARY KEY
          )
        SQL
      end

      def schema_migrations_table_exists?(realm)
        self.class.validate_name!(realm)
        result = connection.select_value(<<~SQL.squish)
          SELECT EXISTS(
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = #{connection.quote(realm.to_s)}
              AND table_name = 'schema_migrations'
          )
        SQL
        ActiveRecord::Type::Boolean.new.cast(result)
      end

      private

      def connection
        ActiveRecord::Base.connection
      end
    end
  end
end
