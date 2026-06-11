# Citadel

Citadel is a Ruby gem for **schema-level multitenancy** in Rails applications using PostgreSQL. Each tenant is a **realm** — an isolated PostgreSQL schema with its own connection pool. Shared tables live in the **foundation** (`public` schema).

## Why schema-level?

| Approach | Isolation | Best for |
|---|---|---|
| Row-level (`WHERE tenant_id = ?`) | Application-enforced | Many tenants, cross-tenant reporting |
| **Schema-level (Citadel)** | Database-enforced | Fewer high-value tenants, regulatory needs |
| Database-level | Full isolation | Strictest separation, per-tenant tuning |

## Requirements

- Ruby 3.2+ (tested on Ruby 4.0)
- Rails 7.2+ / 8.x
- PostgreSQL 14+
- `config.active_support.isolation_level = :fiber` (required for fiber-safe realm switching)

## Installation

Add to your Gemfile:

```ruby
gem "citadel"
```

Run the install generator:

```bash
bin/rails generate citadel:install
```

## Configuration

```ruby
# config/initializers/citadel.rb
Citadel.configure do |config|
  config.isolation = :schema
  config.default_realm = "public"
  config.persistent_schemas = %w[shared_extensions]
  config.realms = -> { Account.pluck(:subdomain) }
  config.gatekeeper = :subdomain
end
```

## Usage

### Enter a realm

```ruby
Citadel::Realm.enter("gondor") do
  Order.count
end

Citadel::Realm.current # => "gondor"
```

### Foundation models (always in `public`)

```ruby
class Account < ApplicationRecord
  include Citadel::Foundation
end
```

### Gatekeepers

The subdomain gatekeeper resolves the realm from the request host and wraps the request in `Realm.enter`:

```
gondor.example.com → realm "gondor"
```

### Rake tasks

```bash
bin/rails citadel:create
bin/rails citadel:migrate
bin/rails citadel:seed
bin/rails citadel:drop
```

`citadel:migrate` runs automatically after `db:migrate` when `migrate_all_realms` is enabled.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT — see [LICENSE.txt](LICENSE.txt).
