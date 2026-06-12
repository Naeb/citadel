# frozen_string_literal: true

RSpec.describe Citadel::Adapters::PostgresqlSchemaAdapter do
  subject(:adapter) { described_class.new }

  describe ".validate_name!" do
    it "accepts valid schema names" do
      expect { described_class.validate_name!("gondor") }.not_to raise_error
      expect { described_class.validate_name!("realm_1") }.not_to raise_error
    end

    it "rejects invalid schema names" do
      expect { described_class.validate_name!("Bad-Name") }
        .to raise_error(Citadel::InvalidSchemaNameError)
      expect { described_class.validate_name!("") }
        .to raise_error(Citadel::InvalidSchemaNameError)
    end
  end

  describe "#schema_search_path_for" do
    before do
      Citadel.configure do |config|
        config.persistent_schemas = %w[shared_extensions]
      end
      Citadel.config.apply_defaults!
    end

    it "builds search path with persistent schemas and public" do
      path = adapter.schema_search_path_for("gondor")
      expect(path).to eq("gondor, shared_extensions, public")
    end

    it "omits duplicate public for default realm" do
      path = adapter.schema_search_path_for("public")
      expect(path).to eq("public, shared_extensions")
    end
  end

  describe "#schema_migrations_table_exists?" do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

    before do
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(connection).to receive(:quote) { |value| "'#{value}'" }
    end

    it "checks information_schema for the realm schema" do
      allow(connection).to receive(:select_value).and_return(true)

      expect(adapter.schema_migrations_table_exists?("gondor")).to be(true)
      expect(connection).to have_received(:select_value).with(
        a_string_including("information_schema.tables", "table_schema = 'gondor'", "schema_migrations")
      )
    end

    it "casts database boolean values" do
      allow(connection).to receive(:select_value).and_return("f")

      expect(adapter.schema_migrations_table_exists?("gondor")).to be(false)
    end

    it "rejects invalid schema names" do
      expect { adapter.schema_migrations_table_exists?("Bad-Name") }
        .to raise_error(Citadel::InvalidSchemaNameError)
    end
  end

  describe "#ensure_schema_migrations_table!" do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

    before do
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(connection).to receive(:quote) { |value| "'#{value}'" }
      allow(connection).to receive(:select_value).and_return(false)
      allow(connection).to receive(:execute)
    end

    it "creates schema_migrations in the realm schema when missing" do
      adapter.ensure_schema_migrations_table!("gondor")

      expect(connection).to have_received(:execute).with(
        a_string_including('CREATE TABLE "gondor".schema_migrations', "version character varying NOT NULL PRIMARY KEY")
      )
    end

    it "does not create the table when it already exists" do
      allow(connection).to receive(:select_value).and_return(true)

      adapter.ensure_schema_migrations_table!("gondor")

      expect(connection).not_to have_received(:execute)
    end

    it "is idempotent across repeated calls" do
      adapter.ensure_schema_migrations_table!("gondor")
      allow(connection).to receive(:select_value).and_return(true)

      adapter.ensure_schema_migrations_table!("gondor")

      expect(connection).to have_received(:execute).once
    end

    it "rejects invalid schema names" do
      expect { adapter.ensure_schema_migrations_table!("Bad-Name") }
        .to raise_error(Citadel::InvalidSchemaNameError)
    end
  end
end
