# frozen_string_literal: true

module Reforge
  class Extractor
    class MemoizedTransform
      def initialize(transform)
        validate_transform!(transform)

        @transform = transform
        @memo = {}
      end

      def call(value)
        @memo[value] ||= @transform.call(value)
      end

      private

      def validate_transform!(transform)
        return if transform.respond_to?(:call)

        raise ArgumentError, "The transform must be callable"
      end
    end
  end
end
