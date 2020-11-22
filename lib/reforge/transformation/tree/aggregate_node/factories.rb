# frozen_string_literal: true

module Reforge
  class Transformation
    class Tree
      class AggregateNode
        module Factories
          IMPLEMENTATION_FACTORIES = {
            Integer => -> { ArrayNode.new },
            String => -> { HashNode.new },
            Symbol => -> { HashNode.new }
          }.freeze
          IMPLEMENTATION_TYPES = IMPLEMENTATION_FACTORIES.keys.freeze

          def implementation_from(key_type)
            validate_key_type!(key_type)

            IMPLEMENTATION_FACTORIES[key_type].call
          end

          private

          def validate_key_type!(key_type)
            return if IMPLEMENTATION_TYPES.include?(key_type)

            raise ArgumentError, "No AggregateNode implementation for key_type #{key_type}"
          end
        end
      end
    end
  end
end
