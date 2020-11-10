# frozen_string_literal: true

module Reforge
  class Tree
    class AggregateNode
      class AggregateNodeTypeError < StandardError; end

      IMPLEMENTATIONS = {
        Integer => ArrayNode,
        String => HashNode,
        Symbol => HashNode
      }.freeze

      attr_reader :implementation

      def initialize(key_type)
        @implementation = create_implementation(key_type)
        @key_type = key_type
      end

      def reforge(source)
        implementation.reforge(source)
      end

      def []=(key, node)
        validate_node!(node)
        validate_key!(key)

        implementation.children[key] = node
      end

      def [](key)
        validate_key!(key)

        implementation.children[key]
      end

      private

      def create_implementation(key_type)
        unless IMPLEMENTATIONS.key?(key_type)
          raise AggregateNodeTypeError, "No AggregateNode implementation for key_type #{key_type}"
        end

        IMPLEMENTATIONS[key_type].new
      end

      def validate_node!(node)
        return if node.is_a?(AggregateNode) || node.is_a?(ExtractorNode)

        raise ArgumentError, "The node must be a Reforge::AggregateNode or Reforge::ExtractorNode"
      end

      def validate_key!(key)
        return if key.is_a?(@key_type)

        raise ArgumentError, "The key must be a #{@key_type}"
      end
    end
  end
end
