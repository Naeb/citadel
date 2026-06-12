# frozen_string_literal: true

RSpec.describe Citadel::Realm do
  before do
    Citadel.configure do |config|
      config.realms = -> { %w[gondor rohan] }
    end
    Citadel.config.apply_defaults!
    Citadel.config.validate!
    described_class.instance_variable_set(:@adapter, nil)
  end

  after do
    described_class.reset!
    described_class.instance_variable_set(:@adapter, nil)
  end

  describe ".enter" do
    it "sets realm for the block duration" do
      described_class.enter("gondor") do
        expect(Citadel::Presence.realm).to eq("gondor")
      end

      expect(Citadel::Presence.realm).to be_nil
    end

    it "restores previous realm after block" do
      Citadel::Presence.realm = "rohan"

      described_class.enter("gondor") do
        expect(Citadel::Presence.realm).to eq("gondor")
      end

      expect(Citadel::Presence.realm).to eq("rohan")
    end

    it "rejects invalid schema names" do
      expect { described_class.enter("Bad-Name") { nil } }
        .to raise_error(Citadel::InvalidSchemaNameError)
    end
  end

  describe ".current" do
    it "returns active realm or default" do
      expect(described_class.current).to eq("public")

      described_class.enter("gondor") do
        expect(described_class.current).to eq("gondor")
      end
    end
  end

  describe ".require_presence!" do
    it "raises when no non-default realm is active" do
      expect { described_class.require_presence! }
        .to raise_error(Citadel::MissingRealmError)
    end

    it "passes when a realm is active" do
      described_class.enter("gondor") do
        expect { described_class.require_presence! }.not_to raise_error
      end
    end
  end

  describe ".names" do
    it "returns configured realm names" do
      expect(described_class.names).to eq(%w[gondor rohan])
    end
  end

  describe ".migrate" do
    let(:adapter) { instance_double(Citadel::Adapters::PostgresqlSchemaAdapter) }
    let(:migration_context) { instance_double(ActiveRecord::MigrationContext) }
    let(:schema_migration) { instance_double(ActiveRecord::SchemaMigration) }
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }

    before do
      allow(Citadel::Adapters::PostgresqlSchemaAdapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:ensure_schema_migrations_table!)
      allow(ActiveRecord::Migrator).to receive(:migrations_paths).and_return(["db/migrate"])
      allow(ActiveRecord::SchemaMigration).to receive(:new).and_return(schema_migration)
      allow(ActiveRecord::MigrationContext).to receive(:new).and_return(migration_context)
      allow(migration_context).to receive(:migrate)
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(connection_pool)
    end

    it "bootstraps schema_migrations for non-default realms" do
      described_class.migrate("gondor")

      expect(adapter).to have_received(:ensure_schema_migrations_table!).with("gondor")
    end

    it "skips schema_migrations bootstrap for the default realm" do
      described_class.migrate("public")

      expect(adapter).not_to have_received(:ensure_schema_migrations_table!)
    end

    it "activates the target realm while migrations run" do
      active_realms = []
      allow(migration_context).to receive(:migrate) { active_realms << Citadel::Presence.realm }

      described_class.migrate("gondor")

      expect(active_realms).to eq(["gondor"])
      expect(Citadel::Presence.realm).to be_nil
    end

    it "migrates all configured realms when no name is given" do
      described_class.migrate

      expect(adapter).to have_received(:ensure_schema_migrations_table!).with("gondor")
      expect(adapter).to have_received(:ensure_schema_migrations_table!).with("rohan")
      expect(migration_context).to have_received(:migrate).twice
    end

    it "delegates to MigrationContext with the active connection pool" do
      described_class.migrate("gondor")

      expect(ActiveRecord::MigrationContext).to have_received(:new).with(
        ["db/migrate"],
        schema_migration
      )
      expect(ActiveRecord::SchemaMigration).to have_received(:new).with(connection_pool)
      expect(migration_context).to have_received(:migrate)
    end
  end

  describe ".create and .drop" do
    let(:adapter) { instance_double(Citadel::Adapters::PostgresqlSchemaAdapter) }

    before do
      allow(Citadel::Adapters::PostgresqlSchemaAdapter).to receive(:new).and_return(adapter)
    end

    it "delegates schema creation to the adapter" do
      allow(adapter).to receive(:create_schema)

      described_class.create("gondor")

      expect(adapter).to have_received(:create_schema).with("gondor")
    end

    it "delegates schema removal to the adapter" do
      allow(adapter).to receive(:drop_schema)

      described_class.drop("gondor")

      expect(adapter).to have_received(:drop_schema).with("gondor")
    end
  end
end
