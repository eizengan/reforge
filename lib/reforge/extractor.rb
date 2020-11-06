# frozen_string_literal: true

module Reforge
  class Extractor
    class ExtractorTypeError < StandardError; end

    IMPLEMENTATIONS = {
      key: KeyExtractor,
      value: ValueExtractor
    }.freeze

    attr_reader :implementation, :transform

    def initialize(type:, args:, transform: nil)
      validate_transform!(transform) unless transform.nil?

      @implementation = create_implementation(type, args)
      @transform = transform
    end

    def extract_from(source)
      value = implementation.extract_from(source)
      transform_value(value)
    end

    private

    def validate_transform!(transform)
      return if transform.is_a?(Proc)

      raise ArgumentError, "Transform must be a Proc"
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
  end
end
