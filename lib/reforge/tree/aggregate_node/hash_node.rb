# frozen_string_literal: true

module Reforge
  class Tree
    class AggregateNode
      class HashNode
        attr_reader :children

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
