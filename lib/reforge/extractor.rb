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
      raise ArgumentError, "The transform must be callable" unless transform.nil? || transform.respond_to?(:call)
      raise ArgumentError, "When present memoize must be true or false" unless [nil, false, true].include?(memoize)

      @implementation = create_implementation(type, args)
      @transform = create_transform(transform, memoize)
    end

    def extract_from(source)
      value = implementation.extract_from(source)
      transform_value(value)
    end

    private

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
      if memoize
        MemoizedTransform.new(transform)
      else
        transform
      end
    end
  end
end
