# frozen_string_literal: true

namespace :citadel do
  desc "Create all configured realms (schemas)"
  task create: :environment do
    Citadel::Realm.names.each do |realm|
      puts "Creating realm #{realm}..."
      Citadel::Realm.create(realm)
    end
  end

  desc "Drop all configured realms (schemas)"
  task drop: :environment do
    Citadel::Realm.names.each do |realm|
      next if realm == Citadel.config.default_realm

      puts "Dropping realm #{realm}..."
      Citadel::Realm.drop(realm)
    end
  end

  desc "Migrate all configured realms"
  task migrate: :environment do
    Citadel::Realm.migrate
  end

  desc "Seed all configured realms"
  task seed: :environment do
    Citadel::Realm.seed
  end
end
