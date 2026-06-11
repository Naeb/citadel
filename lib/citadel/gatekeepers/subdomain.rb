# frozen_string_literal: true

module Citadel
  module Gatekeepers
    class Subdomain < Generic
      private

      def parse_realm(request)
        host = request.host.to_s
        return nil if host.empty?

        parts = host.split(".")
        return nil if parts.length < 2

        parts.first
      end
    end
  end
end
