# frozen_string_literal: true

module Citadel
  module Realm
    class << self
      def enter(realm_name)
        Adapters::PostgresqlSchemaAdapter.validate_name!(realm_name)
        previous = Presence.realm
        Presence.realm = realm_name.to_s
        Presence.previous_realm = previous

        return unless block_given?

        begin
          yield
        ensure
          Presence.realm = previous
          Presence.previous_realm = nil
        end
      end

      def current
        Presence.realm || Citadel.config.default_realm
      end

      def reset!
        Presence.realm = nil
        Presence.previous_realm = nil
      end

      def require_presence!
        active = Presence.realm
        default = Citadel.config.default_realm

        return if active && active.to_s != default.to_s

        raise MissingRealmError, "an active realm is required"
      end

      def names
        Array(Citadel.config.realms.call).map(&:to_s)
      end

      def each(&)
        names.each(&)
      end

      def create(name)
        adapter.create_schema(name)
      end

      def drop(name)
        adapter.drop_schema(name)
      end

      def migrate(name = nil)
        targets = name ? [name.to_s] : names
        targets.each { |realm_name| migrate_one(realm_name) }
      end

      def seed(name = nil)
        targets = name ? [name.to_s] : names
        targets.each do |realm_name|
          enter(realm_name) do
            load_seed_file if seed_file?
          end
        end
      end

      private

      def migrate_one(realm_name)
        enter(realm_name) do
          default_realm = Citadel.config.default_realm
          adapter.ensure_schema_migrations_table!(realm_name) unless realm_name.to_s == default_realm.to_s

          context = ActiveRecord::MigrationContext.new(
            migration_paths,
            ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection_pool)
          )
          context.migrate
        end
      end

      def migration_paths
        ActiveRecord::Migrator.migrations_paths.map do |path|
          next path if Pathname.new(path).absolute?
          next Rails.root.join(path).to_s if defined?(Rails::Application) && Rails.application

          path
        end
      end

      def load_seed_file
        seed_path = Rails.root.join("db/seeds.rb")
        load(seed_path) if seed_path.exist?
      end

      def seed_file?
        defined?(Rails) && Rails.root.join("db/seeds.rb").exist?
      end

      def adapter
        @adapter ||= Adapters::PostgresqlSchemaAdapter.new
      end
    end
  end
end
