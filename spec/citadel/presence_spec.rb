# frozen_string_literal: true

RSpec.describe Citadel::Presence do
  after { described_class.reset }

  it "stores and resets realm context" do
    described_class.realm = "gondor"
    described_class.previous_realm = "public"

    expect(described_class.realm).to eq("gondor")
    expect(described_class.previous_realm).to eq("public")

    described_class.reset
    expect(described_class.realm).to be_nil
    expect(described_class.previous_realm).to be_nil
  end
end
