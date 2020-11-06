# frozen_string_literal: true

module Reforge
  class Extractor
    class ExtractorTypeError < StandardError; end

    IMPLEMENTATIONS = {
      key: KeyExtractor,
      value: ValueExtractor
    }.freeze

    attr_reader :implementation

    def initialize(type:, args:)
      @implementation = create_implementation(type, args)
    end

    def extract_from(source)
      implementation.extract_from(source)
    end

    private

    def create_implementation(type, args)
      implementation_class_from(type).new(*args)
    end

    def implementation_class_from(type)
      raise ExtractorTypeError, "No Extractor implementation for type '#{type}'" unless IMPLEMENTATIONS.key?(type)

      IMPLEMENTATIONS[type]
    end
  end
end
