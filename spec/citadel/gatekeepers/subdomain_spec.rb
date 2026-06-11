# frozen_string_literal: true

require "rack/mock"

RSpec.describe Citadel::Gatekeepers::Subdomain do
  subject(:gatekeeper) { described_class.new(->(env) { env }) }

  before do
    Citadel.configure do |config|
      config.default_realm = "public"
    end
    Citadel.config.apply_defaults!
  end

  after { Citadel::Realm.reset! }

  it "resolves realm from subdomain" do
    env = Rack::MockRequest.env_for("http://gondor.example.com/orders")

    gatekeeper.call(env)

    expect(Citadel::Presence.realm).to be_nil
  end

  it "enters realm during request" do
    entered = nil
    app = lambda do |_env|
      entered = Citadel::Presence.realm
      [200, {}, ["ok"]]
    end

    gatekeeper = described_class.new(app)
    gatekeeper.call(Rack::MockRequest.env_for("http://gondor.example.com/"))

    expect(entered).to eq("gondor")
    expect(Citadel::Presence.realm).to be_nil
  end

  it "falls back to default realm for bare hosts" do
    entered = nil
    app = lambda do |_env|
      entered = Citadel::Presence.realm
      [200, {}, ["ok"]]
    end

    described_class.new(app).call(Rack::MockRequest.env_for("http://localhost/"))

    expect(entered).to eq("public")
  end
end
