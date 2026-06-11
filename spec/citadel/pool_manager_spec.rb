# frozen_string_literal: true

RSpec.describe Citadel::PoolManager do
  let(:db_config) do
    ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test",
      "primary",
      { adapter: "postgresql", database: "citadel_test" }
    )
  end
  let(:schema_adapter) { instance_double(Citadel::Adapters::PostgresqlSchemaAdapter) }

  before do
    Citadel.configure do |config|
      config.persistent_schemas = []
      config.default_realm = "public"
    end
    Citadel.config.apply_defaults!

    allow(ActiveRecord::Base).to receive(:connection_db_config).and_return(db_config)
    allow(Citadel::Adapters::PostgresqlSchemaAdapter).to receive(:new).and_return(schema_adapter)
    allow(schema_adapter).to receive(:schema_search_path_for).with("rohan").and_return("rohan, public")
    described_class.instance_variable_set(:@adapter, nil)
  end

  after do
    Citadel::Presence.reset
    described_class.clear!
  end

  describe ".pool_for" do
    it "returns the pool from establish_connection" do
      pool = instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool, disconnect!: nil)
      handler = instance_double(ActiveRecord::ConnectionAdapters::ConnectionHandler)
      allow(ActiveRecord::ConnectionAdapters::ConnectionHandler).to receive(:new).and_return(handler)
      allow(handler).to receive(:establish_connection).and_return(pool)

      expect(described_class.pool_for("rohan")).to eq(pool)
    end

    it "reuses cached pools for the same realm and role" do
      pool = instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool, disconnect!: nil)
      handler = instance_double(ActiveRecord::ConnectionAdapters::ConnectionHandler)
      allow(ActiveRecord::ConnectionAdapters::ConnectionHandler).to receive(:new).and_return(handler)
      allow(handler).to receive(:establish_connection).and_return(pool)

      first = described_class.pool_for("rohan")
      second = described_class.pool_for("rohan")

      expect(first).to equal(second)
      expect(handler).to have_received(:establish_connection).once
    end
  end

  describe "pool configuration" do
    before { Citadel::Presence.realm = "gondor" }

    it "reads base config without active realm context" do
      active_during_read = nil
      allow(ActiveRecord::Base).to receive(:connection_db_config) do
        active_during_read = Citadel::Presence.realm
        db_config
      end

      described_class.send(:pool_config_for, "rohan", :writing)

      expect(active_during_read).to be_nil
      expect(Citadel::Presence.realm).to eq("gondor")
    end

    it "restores realm context when connection_db_config raises" do
      allow(ActiveRecord::Base).to receive(:connection_db_config).and_raise(StandardError, "boom")

      expect { described_class.send(:pool_config_for, "rohan", :writing) }
        .to raise_error(StandardError, "boom")
      expect(Citadel::Presence.realm).to eq("gondor")
    end

    it "builds pool config with search path for the target realm" do
      config = described_class.send(:pool_config_for, "rohan", :writing)

      expect(config.configuration_hash[:schema_search_path]).to eq("rohan, public")
      expect(config.configuration_hash[:citadel_realm]).to eq("rohan")
      expect(config.name).to eq("citadel_rohan_writing")
    end
  end
end
