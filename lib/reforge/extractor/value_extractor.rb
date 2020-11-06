# frozen_string_literal: true

module Reforge
  class Extractor
    class ValueExtractor
      def initialize(value)
        @value = value
      end

      def extract_from(_source)
        @value
      end
    end
  end
end
