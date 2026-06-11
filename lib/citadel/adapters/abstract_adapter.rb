# frozen_string_literal: true

module Citadel
  module Adapters
    class AbstractAdapter
      def create_schema(_name)
        raise NotImplementedError
      end

      def drop_schema(_name)
        raise NotImplementedError
      end

      def schema_exists?(_name)
        raise NotImplementedError
      end

      def schema_search_path_for(_realm)
        raise NotImplementedError
      end
    end
  end
end
