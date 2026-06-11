# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-06-10

### Added

- Pool-per-realm PostgreSQL schema isolation
- `Citadel::Realm.enter` for block-scoped realm switching
- `Citadel::Presence` fiber-safe context via `CurrentAttributes`
- `Citadel::Foundation` concern for models anchored to `public`
- `Citadel::Gatekeepers::Subdomain` Rack middleware
- Rake tasks: `citadel:create`, `citadel:drop`, `citadel:migrate`, `citadel:seed`
- `rails generate citadel:install` generator
- RBS signatures for public API
