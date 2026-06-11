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
end
