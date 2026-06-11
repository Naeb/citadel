# frozen_string_literal: true

RSpec.describe Citadel::Foundation do
  let(:model_class) do
    Class.new do
      def self.name = "Account"

      def self.table_name = "accounts"

      include Citadel::Foundation
    end
  end

  it "qualifies table name with public schema" do
    expect(model_class.table_name).to eq("public.accounts")
  end

  it "registers the model in configuration" do
    model_class
    expect(Citadel.config.foundation_models).to include("Account")
  end
end
