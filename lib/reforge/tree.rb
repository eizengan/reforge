# frozen_string_literal: true

module Reforge
  class Tree
    class NodeRedefinitionError < StandardError; end
    class PathPartError < StandardError; end

    attr_reader :root

    def attach_transform(*path)
      validate_path!(*path)

      # TRICKY: A single-step path means we are wrapping a single transform. We set the root node accordingly, allowing
      # it to fail loudly if it is being redefined
      #
      # A multi-step path means we are wrapping a branching tree with transforms at its leaf nodes. We only initialize
      # the root node if we have not done so already, and then begin attaching the nodes necessitated by the supplied
      # path. The nodes are expected to fail loudly if their attachment rules are violated
      if path.size == 1
        initialize_root(path[0])
      else
        initialize_root(path[0]) if root.nil?
        attach_nodes(*path)
      end

      nil
    end

    def call(source)
      root.call(source)
    end

    private

    def validate_path!(*path, transform)
      raise ArgumentError, "The path must end with a Reforge::Transform" unless transform.is_a?(Transform)

      path.each { |path_part| validate_path_part!(path_part) }
    end

    def validate_path_part!(path_part)
      return if AggregateNode::IMPLEMENTATION_TYPES.include?(path_part.class)

      raise ArgumentError, "The path includes '#{path_part}' which has unknown key type #{path_part.class}"
    end

    def initialize_root(path_part)
      raise NodeRedefinitionError, "The root node has already been defined" unless root.nil?

      @root = create_node(path_part)
    end

    def attach_nodes(*path, transform)
      node = root

      # TRICKY: we need two contiguous steps in the path to create and attach a node. The first tells where on the
      # parent node to attach the new node, and the second allows us to infer which type of node we need to attach.
      #
      # As an example, in attach_nodes(:foo, 0, :bar, transform) the pair of steps [:foo, 0] would tell us we need to
      # attach an ArrayNode (inferred by 0) at root's :foo index. We then move to [0, :bar], which tell us we need to
      # attach a HashNode (inferred by :bar) at the ArrayNode's 0 index. Finally we move to [:bar, transform], which
      # tells us to attach an TransformNode (inferred by transform) at the HashNode's :bar index
      #
      # To fulfill this requirement we turn the arguments to this method into offset arrays and zip them together. Use
      # of ||= is inappropriate during TransformNode attachment because it will not attempt to create and attach the
      # node if a child with the same key already exists, so we just use = below
      parent_path_parts = path[0..-2]
      child_path_parts = path[1..]
      parent_path_parts.zip(child_path_parts).each do |parent_path_part, child_path_part|
        node = node[parent_path_part] ||= create_node(child_path_part)
      end

      node[path[-1]] = create_node(transform)
    end

    def create_node(path_part)
      if AggregateNode::IMPLEMENTATION_TYPES.include?(path_part.class)
        AggregateNode.new(path_part.class)
      elsif path_part.is_a?(Transform)
        TransformNode.new(path_part)
      else
        raise PathPartError, "Cannot create node from path_part type #{step.class}"
      end
    end
  end
end
