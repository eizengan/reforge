# frozen_string_literal: true

module Reforge
  class Transform
    COMMON_TRANSFORMS = {
      attribute: ->(attribute) { attribute_transform_for(attribute) },
      key: ->(key) { key_transform_for(key) },
      value: ->(value) { value_transform_for(value) }
    }.freeze
    ALLOWED_COMMON_TRANSFORM_TYPES = COMMON_TRANSFORMS.keys.freeze

    def self.attribute_transform_for(attribute)
      ->(source) { source.send(attribute) }
    end

    def self.key_transform_for(key)
      ->(source) { source[key] }
    end

    def self.value_transform_for(value)
      ->(_source) { value }
    end

    attr_reader :transform

    def initialize(transform:, memoize: nil)
      validate_transform!(transform)
      validate_memoize!(memoize)

      transform = transform_from_config_hash(transform) if transform.is_a?(Hash)
      @transform = create_transform(transform, memoize)
    end

    def call(source)
      transform.call(source)
    end

    private

    def validate_transform!(transform)
      return if transform.respond_to?(:call) || transform_configuration_hash?(transform)

      raise ArgumentError, "The transform must be callable or a configuration hash"
    end

    def transform_configuration_hash?(transform)
      transform.is_a?(Hash) && transform.size == 1 && ALLOWED_COMMON_TRANSFORM_TYPES.include?(transform.keys[0])
    end

    def validate_memoize!(memoize)
      return if [nil, false, true].include?(memoize) || memoize.is_a?(Hash)

      raise ArgumentError, "The memoize option must be true, false, or a configuration hash"
    end

    def transform_from_config_hash(config)
      config.map { |type, arg| COMMON_TRANSFORMS[type].call(arg) }.first
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
