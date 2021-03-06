# frozen_string_literal: true

module Reforge
  class Transformation
    class TreeCreationError < StandardError; end

    module DSL
      def extract(path = nil, from:, memoize: nil)
        transform_definitions.push(
          {
            path: path,
            transform: from,
            memoize: memoize
          }.compact
        )
      end

      # TRICKY: we want to support e.g. the following equivalent calls:
      # - transform key: 0, into: [:foo, :bar]
      # - transform ->(source) { source[0] }, into: [:foo, :bar]
      # but in the former case the arguments are collapsed into a single hash which is used as the transform arg. By
      # using **transform_hash we can avoid this behavior, but as a result the transform could be in either the
      # transform argument or the transform_hash
      def transform(transform = nil, into: nil, memoize: nil, **transform_hash)
        transform_definitions.push(
          {
            path: into,
            transform: transform || transform_hash,
            memoize: memoize
          }.compact
        )
      end

      def create_tree
        transform_definitions.each_with_object(Tree.new) do |transform_definition, tree|
          transform = Transform.new(
            transform_definition[:transform],
            memoize: transform_definition[:memoize]
          )
          tree.attach_transform(*transform_definition[:path], transform)
        rescue StandardError => e
          raise TreeCreationError, "Failed to attach node at path #{[*transform_definition[:path]]} - #{e.message}"
        end
      end

      def transform_definitions
        @transform_definitions ||= []
      end
    end
  end
end
