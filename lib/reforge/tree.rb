# frozen_string_literal: true

module Reforge
  class Tree
    class PathTypeError < StandardError; end

    attr_reader :root

    def add_extractor(*path, extractor)
      validate_extractor!(extractor)

      node = @root ||= create_node(path[0])

      # TRICKY: we need two contiguous steps in the path to create and attach a node. The first tells where on the
      # parent node to attach the new node, and the second allows us to infer which type of node we need to attach.
      #
      # As an example, in add_extractor(:foo, 0, :bar, extractor) the pair of steps [:foo, 0] would tell us we need to
      # attach an ArrayNode (inferred by 0) at @root's :foo index. We then move to [0, :bar], which tell us we need to
      # attach a HashNode (inferred by :bar) at the ArrayNode's 0 index. Finally we move to [:bar, extractor], which
      # tells us to attach an ExtractorNode (inferred by extractor) at the HashNode's :bar index
      #
      # To fulfill this requirement we turn the arguments to this method into offset arrays and zip them together
      next_path_steps = [*path[1..], extractor]
      path.zip(next_path_steps).each do |step, next_step|
        node = node[step] ||= create_node(next_step)
      end

      self
    end

    def reforge(source)
      root.reforge(source)
    end

    private

    def validate_extractor!(extractor)
      return if extractor.is_a?(Extractor)

      raise ArgumentError, "The extractor must be a Reforge::Extractor"
    end

    def create_node(step)
      if AggregateNode::ALLOWED_KEY_TYPES.include?(step.class)
        AggregateNode.new(step.class)
      elsif step.is_a?(Extractor)
        ExtractorNode.new(step)
      else
        raise PathTypeError, "Path includes an element of type #{step.class} with no corresponding node type"
      end
    end
  end
end
