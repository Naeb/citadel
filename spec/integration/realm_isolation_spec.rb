# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Citadel integration", type: :integration do
  before(:all) do
    @previous_dir = Dir.pwd
    dummy_root = File.expand_path("../dummy", __dir__)
    ENV["RAILS_ENV"] = "test"
    ENV["BUNDLE_GEMFILE"] = File.join(dummy_root, "Gemfile")

    Dir.chdir(dummy_root) do
      require File.expand_path("config/environment", dummy_root)
    end

    skip "PostgreSQL not available" unless pg_available?

    reset_schemas!
    migrate_public!
    create_and_migrate_realms!
  end

  after(:all) do
    Dir.chdir(@previous_dir) if @previous_dir
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

  it "creates schema_migrations in each realm schema during migrate" do
    expect(schema_migrations_table_exists?("gondor")).to be(true)
    expect(schema_migrations_table_exists?("rohan")).to be(true)
    expect(schema_migrations_table_exists?("public")).to be(true)
  end

  it "bootstraps schema_migrations when migrating a freshly created realm" do
    conn = ActiveRecord::Base.connection
    conn.execute("DROP SCHEMA IF EXISTS erebor CASCADE")
    Citadel::Realm.create("erebor")

    expect(schema_migrations_table_exists?("erebor")).to be(false)

    Citadel::Realm.migrate("erebor")

    expect(schema_migrations_table_exists?("erebor")).to be(true)
  ensure
    conn.execute("DROP SCHEMA IF EXISTS erebor CASCADE")
  end

  it "uses the target realm search path even when another realm is active" do
    Citadel::Realm.enter("gondor") do
      Citadel::Realm.enter("rohan") do
        search_path = ActiveRecord::Base.connection.select_value("SHOW search_path")

        expect(search_path).to include("rohan")
        expect(search_path).not_to start_with("gondor")
      end
    end
  end

  it "tracks migration versions independently per realm" do
    gondor_versions = versions_in_schema("gondor")
    rohan_versions = versions_in_schema("rohan")

    expect(gondor_versions).not_to be_empty
    expect(rohan_versions).to eq(gondor_versions)

    conn = ActiveRecord::Base.connection
    conn.execute("INSERT INTO gondor.schema_migrations (version) VALUES ('99999999999999')")

    expect(versions_in_schema("gondor")).to include("99999999999999")
    expect(versions_in_schema("rohan")).not_to include("99999999999999")
  ensure
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM gondor.schema_migrations WHERE version = '99999999999999'")
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

  def schema_migrations_table_exists?(schema)
    result = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = #{ActiveRecord::Base.connection.quote(schema)}
          AND table_name = 'schema_migrations'
      )
    SQL
    ActiveRecord::Type::Boolean.new.cast(result)
  end

  def versions_in_schema(schema)
    ActiveRecord::Base.connection.select_values(
      "SELECT version FROM #{schema}.schema_migrations ORDER BY version"
    )
  end
end
