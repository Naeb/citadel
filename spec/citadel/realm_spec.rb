# frozen_string_literal: true

RSpec.describe Citadel::Realm do
  before do
    Citadel.configure do |config|
      config.realms = -> { %w[gondor rohan] }
    end
    Citadel.config.apply_defaults!
    Citadel.config.validate!
  end

  after { described_class.reset! }

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
end
