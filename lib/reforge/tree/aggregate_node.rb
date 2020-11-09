# frozen_string_literal: true

module Reforge
  class Tree
    class AggregateNode
      class AggregateNodeTypeError < StandardError; end

      IMPLEMENTATIONS = {
        array: ArrayNode,
        hash: HashNode
      }.freeze

      attr_reader :implementation

      def initialize(type)
        @implementation = create_implementation(type)
      end

      def reforge(source)
        implementation.reforge(source)
      end

      def add_child(key, node)
        validate_node!(node)
        implementation.class.validate_key!(key)

        implementation.children[key] = node
      end

      def child_at(key)
        implementation.class.validate_key!(key)

        implementation.children[key]
      end

      private

      def create_implementation(type)
        unless IMPLEMENTATIONS.key?(type)
          raise AggregateNodeTypeError, "No AggregateNode implementation for type '#{type}'"
        end

        IMPLEMENTATIONS[type].new
      end

      def validate_node!(node)
        return if node.is_a?(AggregateNode) || node.is_a?(ExtractorNode)

        raise ArgumentError, "The node must be a Reforge::AggregateNode or Reforge::ExtractorNode"
      end
    end
  end
end
