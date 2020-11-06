# frozen_string_literal: true

module Reforge
  class Extractor
    class KeyExtractor
      def initialize(key)
        @key = key
      end

      def extract_from(source)
        source[@key]
      end
    end
  end
end
