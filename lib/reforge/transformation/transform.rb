# frozen_string_literal: true

module Reforge
  class Transformation
    class Transform
      include Factories

      attr_reader :transform

      def initialize(transform, memoize: nil)
        transform = transform_proc_from(transform) if transform.is_a?(Hash)
        validate_transform!(transform)

        @transform = transform
        @memo = Memo.from(memoize) if memoize
      end

      def call(source)
        if @memo.nil?
          @transform.call(source)
        else
          @memo[source] ||= @transform.call(source)
        end
      end

      private

      def validate_transform!(transform)
        return if transform.respond_to?(:call)

        raise ArgumentError, "The transform must be callable"
      end
    end
  end
end
