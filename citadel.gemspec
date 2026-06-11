# frozen_string_literal: true

require_relative "lib/citadel/version"

Gem::Specification.new do |spec|
  spec.name = "citadel"
  spec.version = Citadel::VERSION
  spec.authors = ["Guilherme Berlintes"]
  spec.email = ["guilherme.berlintes@outlook.com"]

  spec.summary = "Multi-schema PostgreSQL isolation for Rails via realms, gatekeepers, and foundation models"
  spec.description = "Citadel provides schema-per-realm multitenancy for Rails and ActiveRecord " \
                     "with pool-per-realm connections, fiber-safe presence tracking, and declarative " \
                     "foundation models anchored to the public schema."
  spec.homepage = "https://github.com/berlintes/citadel"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.2", "< 9"
  spec.add_dependency "activesupport", ">= 7.2", "< 9"
  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "rack", ">= 3.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
