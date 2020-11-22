# frozen_string_literal: true

module Reforge
  class Transformation
    class Tree
      class AggregateNode
        class ArrayNode
          attr_reader :children

          def initialize
            @children = []
          end

          def call(source)
            # TRICKY: holes can be present, e.g. at key 1 after setting children at keys 0 and 2
            children.map { |child| child&.call(source) }
          end
        end
      end
    end
  end
end
