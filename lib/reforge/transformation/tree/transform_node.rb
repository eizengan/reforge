# frozen_string_literal: true

module Reforge
  class Transformation
    class Tree
      class TransformNode
        attr_reader :transform

        def initialize(transform)
          validate_transform!(transform)

          @transform = transform
        end

        def call(source)
          transform.call(source)
        end

        private

        def validate_transform!(transform)
          return if transform.is_a?(Transform)

          raise ArgumentError, "The transform must be a Transform"
        end
      end
    end
  end
end
