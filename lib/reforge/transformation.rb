# frozen_string_literal: true

module Reforge
  class Transformation
    extend DSL

    def self.call(*sources)
      new.call(*sources)
    end

    def call(*sources)
      return tree.call(sources[0]) if sources.size == 1

      sources.map { |source| tree.call(source) }
    end

    private

    def tree
      @tree ||= self.class.create_tree
    end
  end
end
