# frozen_string_literal: true

module Reforge
  class Tree
    class AggregateNode
      class HashNode
        attr_reader :children

        def self.validate_key!(key)
          return if key.is_a?(Symbol) || key.is_a?(String)

          raise ArgumentError, "The key must be a Symbol or String"
        end

        def initialize
          @children = {}
        end

        def reforge(source)
          children.transform_values { |child| child.reforge(source) }
        end
      end
    end
  end
end
