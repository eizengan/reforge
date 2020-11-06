# frozen_string_literal: true

module Reforge
  class Extractor
    class MemoizedTransform
      def initialize(transform)
        raise ArgumentError, "The transform must be callable" unless transform.respond_to?(:call)

        @transform = transform
        @memo = {}
      end

      def call(value)
        @memo[value] ||= @transform.call(value)
      end
    end
  end
end
