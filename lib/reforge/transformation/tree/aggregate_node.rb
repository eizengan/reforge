# frozen_string_literal: true

module Reforge
  class Transformation
    class Tree
      class AggregateNode
        include Factories

        attr_reader :implementation

        def initialize(key_type)
          @path = []
          @implementation = implementation_from(key_type)
          @key_type = key_type
        end

        def call(source)
          implementation.call(source)
        end

        def []=(key, node)
          validate_node!(node)
          validate_key!(key)
          validate_no_redefinition!(key)

          implementation.children[key] = node
          node.update_path(@path + [key])
          node # rubocop:disable Lint/Void
        end

        def [](key)
          validate_key!(key)

          implementation.children[key]
        end

        def update_path(path)
          @path = path
          implementation.update_path(path)
        end

        private

        def validate_node!(node)
          return if node.is_a?(AggregateNode) || node.is_a?(TransformNode)

          raise ArgumentError, "The node must be an AggregateNode or TransformNode"
        end

        def validate_key!(key)
          return if key.is_a?(@key_type)

          raise ArgumentError, "The key must be a #{@key_type}"
        end

        def validate_no_redefinition!(key)
          return if implementation.children[key].nil?

          raise NodeRedefinitionError, "A node already exists at key '#{key}'"
        end
      end
    end
  end
end
