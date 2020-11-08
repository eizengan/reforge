# frozen_string_literal: true

module Reforge
  class Extractor
    class ExtractorTypeError < StandardError; end

    IMPLEMENTATIONS = {
      key: KeyExtractor,
      value: ValueExtractor
    }.freeze

    attr_reader :implementation, :transform

    def initialize(type:, args:, transform: nil, memoize: nil)
      validate_transform!(transform)
      validate_memoize!(memoize)

      @implementation = create_implementation(type, args)
      @transform = create_transform(transform, memoize)
    end

    def extract_from(source)
      value = implementation.extract_from(source)
      transform_value(value)
    end

    private

    def validate_transform!(transform)
      return if transform.nil? || transform.respond_to?(:call)

      raise ArgumentError, "The transform must be callable"
    end

    def validate_memoize!(memoize)
      return if [nil, false, true].include?(memoize) || memoize.is_a?(Hash)

      raise ArgumentError, "The memoize option must be true, false, or a configuration hash"
    end

    def transform_value(value)
      return value if transform.nil?

      transform.call(value)
    end

    def create_implementation(type, args)
      implementation_class_from(type).new(*args)
    end

    def implementation_class_from(type)
      raise ExtractorTypeError, "No Extractor implementation for type '#{type}'" unless IMPLEMENTATIONS.key?(type)

      IMPLEMENTATIONS[type]
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
