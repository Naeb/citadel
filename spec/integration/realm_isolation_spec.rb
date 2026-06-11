# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../dummy/Gemfile", __dir__)

require File.expand_path("../dummy/config/environment", __dir__)

RSpec.describe "Citadel integration", type: :integration do
  before(:all) do
    skip "PostgreSQL not available" unless pg_available?

    reset_schemas!
    migrate_public!
    create_and_migrate_realms!
  end

  after(:each) do
    Citadel::Realm.reset!
  end

  it "isolates realm-scoped records per schema" do
    Citadel::Realm.enter("gondor") { Order.create!(label: "gondor-order") }
    Citadel::Realm.enter("rohan") { Order.create!(label: "rohan-order") }

    expect(Citadel::Realm.enter("gondor") { Order.pluck(:label) }).to eq(["gondor-order"])
    expect(Citadel::Realm.enter("rohan") { Order.pluck(:label) }).to eq(["rohan-order"])
  end

  it "keeps foundation models in public across realms" do
    account = Account.create!(name: "global")

    Citadel::Realm.enter("gondor") do
      expect(Account.find(account.id).name).to eq("global")
    end

    expect(Account.table_name).to eq("public.accounts")
  end

  it "uses a dedicated connection pool per realm" do
    default_pool = ActiveRecord::Base.connection_pool

    gondor_pool = nil
    Citadel::Realm.enter("gondor") do
      gondor_pool = ActiveRecord::Base.connection_pool
    end

    rohan_pool = nil
    Citadel::Realm.enter("rohan") do
      rohan_pool = ActiveRecord::Base.connection_pool
    end

    expect(gondor_pool).not_to eq(default_pool)
    expect(rohan_pool).not_to eq(default_pool)
    expect(gondor_pool).not_to eq(rohan_pool)
  end

  def self.pg_available?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def pg_available?
    self.class.pg_available?
  end

  def reset_schemas!
    conn = ActiveRecord::Base.connection
    conn.execute("DROP SCHEMA IF EXISTS gondor CASCADE")
    conn.execute("DROP SCHEMA IF EXISTS rohan CASCADE")
    conn.execute("DROP TABLE IF EXISTS public.accounts CASCADE")
    conn.execute("DROP TABLE IF EXISTS public.orders CASCADE")
    conn.execute("DROP TABLE IF EXISTS schema_migrations")
  end

  def migrate_public!
    ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
  end

  def create_and_migrate_realms!
    Citadel::Realm.create("gondor")
    Citadel::Realm.create("rohan")
    Citadel::Realm.migrate("gondor")
    Citadel::Realm.migrate("rohan")
  end
end
