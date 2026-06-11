# frozen_string_literal: true

require "active_support"
require "active_support/current_attributes"

module Citadel
  class Presence < ActiveSupport::CurrentAttributes
    attribute :realm
    attribute :previous_realm
  end
end
