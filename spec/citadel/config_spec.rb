# frozen_string_literal: true

RSpec.describe Citadel::Config do
  subject(:config) { described_class.new }

  describe "#apply_defaults!" do
    before { config.apply_defaults! }

    it "sets schema isolation defaults" do
      expect(config.isolation).to eq(:schema)
      expect(config.default_realm).to eq("public")
      expect(config.realms).to respond_to(:call)
      expect(config.migrate_all_realms).to be(true)
    end
  end

  describe "#validate!" do
    before do
      config.realms = -> { %w[gondor rohan] }
      config.apply_defaults!
    end

    it "passes with valid configuration" do
      expect { config.validate! }.not_to raise_error
    end

    it "requires schema isolation" do
      config.isolation = :database
      expect { config.validate! }.to raise_error(Citadel::ConfigurationError, /isolation/)
    end

    it "requires callable realms" do
      config.realms = []
      expect { config.validate! }.to raise_error(Citadel::ConfigurationError, /realms/)
    end
  end

  describe "#register_foundation_model" do
    it "tracks foundation model names" do
      config.register_foundation_model("Account")
      expect(config.foundation_models).to include("Account")
    end
  end

  describe "#freeze!" do
    it "prevents further configuration" do
      config.freeze!
      expect { config.configure { |c| c.default_realm = "other" } }
        .to raise_error(Citadel::ConfigurationError, /frozen/)
    end
  end
end
