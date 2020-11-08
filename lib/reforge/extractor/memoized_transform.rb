# frozen_string_literal: true

module Reforge
  class Extractor
    class MemoizedTransform
      def initialize(transform, **memoize_configuration)
        validate_transform!(transform)
        validate_memoize_by!(memoize_configuration[:by])

        @transform = transform
        @memoize_by = memoize_configuration[:by]
        @memo = {}
      end

      def call(value)
        key = memo_key_from(value)
        @memo[key] ||= @transform.call(value)
      end

      private

      def validate_transform!(transform)
        return if transform.respond_to?(:call)

        raise ArgumentError, "The transform must be callable"
      end

      def validate_memoize_by!(memoize_by)
        return if memoize_by.nil? || memoize_by.respond_to?(:call)

        raise ArgumentError, "The :by option of the configuration hash must be callable"
      end

      def memo_key_from(value)
        if @memoize_by.nil?
          value
        else
          @memoize_by.call(value)
        end
      end
    end
  end
end
