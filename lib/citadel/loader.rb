# frozen_string_literal: true

require "zeitwerk"

module Citadel
  module Loader
    module_function

    def setup
      loader = Zeitwerk::Loader.new
      loader.tag = "citadel"
      loader.inflector.inflect(
        "postgresql_schema_adapter" => "PostgresqlSchemaAdapter"
      )
      loader.push_dir(File.join(__dir__), namespace: Citadel)
      loader.ignore(File.join(__dir__, "tasks"))
      loader.ignore(File.join(__dir__, "errors.rb"))
      loader.setup
      loader
    end
  end
end
