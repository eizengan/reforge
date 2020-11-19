# frozen_string_literal: true

module Reforge
  class Transform
    class MemoizedTransform
      def initialize(transform, **memoize_configuration)
        validate_transform!(transform)

        @transform = transform
        @memo_key_transform = memo_key_transform_from(memoize_configuration[:by])
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

      def memo_key_transform_from(memoize_by)
        return if memoize_by.nil?

        Transform.new(transform: memoize_by)
      rescue ArgumentError
        # TRICKY: Transform didn't like memoize_by, but we want to raise an error specific to memoize_by, not the
        # one directly from Transform
        raise ArgumentError, "The :by option of the configuration hash must be callable or a transform " \
                             "configuration hash"
      end

      def memo_key_from(value)
        if @memo_key_transform.nil?
          value
        else
          @memo_key_transform.call(value)
        end
      end
    end
  end
end
