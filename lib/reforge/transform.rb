# frozen_string_literal: true

module Reforge
  class Transform
    attr_reader :transform

    include Factories

    def initialize(transform:, memoize: nil)
      transform = proc_from_configuration_hash(transform) if transform.is_a?(Hash)

      validate_transform!(transform)
      validate_memoize!(memoize)

      @transform = create_transform(transform, memoize)
    end

    def call(source)
      transform.call(source)
    end

    private

    def validate_transform!(transform)
      return if transform.respond_to?(:call)

      raise ArgumentError, "The transform must be callable"
    end

    def validate_memoize!(memoize)
      return if [nil, false, true].include?(memoize) || memoize.is_a?(Hash)

      raise ArgumentError, "The memoize option must be true, false, or a configuration hash"
    end

    def create_transform(transform, memoize)
      if memoize.is_a?(Hash)
        MemoizedTransform.new(transform, **memoize)
      elsif memoize
        MemoizedTransform.new(transform)
      else
        transform
      end
    end
  end
end
