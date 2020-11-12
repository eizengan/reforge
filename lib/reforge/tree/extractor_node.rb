# frozen_string_literal: true

module Reforge
  class Tree
    class ExtractorNode
      attr_reader :extractor

      def initialize(extractor)
        validate_extractor!(extractor)

        @extractor = extractor
      end

      def reforge(source)
        extractor.extract_from(source)
      end

      private

      def validate_extractor!(extractor)
        return if extractor.is_a?(Extractor)

        raise ArgumentError, "The extractor must be a Reforge::Extractor"
      end
    end
  end
end
