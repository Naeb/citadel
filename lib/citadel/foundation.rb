# frozen_string_literal: true

require "active_support/concern"

module Citadel
  module Foundation
    extend ActiveSupport::Concern

    included do
      Citadel.config.register_foundation_model(self)
      singleton_class.prepend(TableName)
    end

    module TableName
      def table_name
        base = super
        return base if base.include?(".")

        "public.#{base}"
      end
    end
  end
end
