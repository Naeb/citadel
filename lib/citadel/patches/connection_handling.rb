# frozen_string_literal: true

module Citadel
  module Patches
    module ConnectionHandling
      module InstanceMethods
        def connection_pool
          return super unless citadel_active?

          realm = Citadel::Presence.realm
          return super if realm.nil?

          default_realm = Citadel.config.default_realm
          return super if realm.to_s == default_realm.to_s

          Citadel::PoolManager.pool_for(realm, role: current_role)
        end

        private

        def citadel_active?
          defined?(Citadel) && Citadel.config&.frozen?
        end
      end

      def self.apply!
        ActiveRecord::Base.singleton_class.prepend(InstanceMethods)
      end
    end
  end
end
