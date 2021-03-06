# frozen_string_literal: true

module Reforge
  class Transformation
    class Tree
      class AggregateNode
        class HashNode
          attr_reader :children

          def initialize
            @children = {}
          end

          def call(source)
            children.transform_values { |child| child.call(source) }
          end

          def update_path(path)
            children.each { |key, child| child.update_path(path + [key]) }
          end
        end
      end
    end
  end
end
