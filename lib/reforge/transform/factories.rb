# frozen_string_literal: true

module Reforge
  class Transform
    module Factories
      TRANSFORM_PROC_FACTORIES = {
        attribute: ->(*attributes, **config) { attribute_transform_for(*attributes, **config) },
        key: ->(*keys, **config) { key_transform_for(*keys, **config) },
        value: ->(value, **_config) { value_transform_for(value) }
      }.freeze
      TRANSFORM_TYPES = TRANSFORM_PROC_FACTORIES.keys.freeze

      def transform_proc_from(config)
        validate_config!(config)

        type = config.keys.detect { |key| TRANSFORM_TYPES.include?(key) }
        args = config.delete(type)

        TRANSFORM_PROC_FACTORIES[type].call(*args, **config)
      end

      private_class_method def self.attribute_transform_for(*attributes, propogate_nil: false)
        recursive_method_call(:send, *attributes, propogate_nil: propogate_nil)
      end

      private_class_method def self.key_transform_for(*keys, propogate_nil: false)
        recursive_method_call(:[], *keys, propogate_nil: propogate_nil)
      end

      private_class_method def self.value_transform_for(value)
        ->(_source) { value }
      end

      private_class_method def self.recursive_method_call(method, *arguments, propogate_nil: false)
        if propogate_nil
          ->(source) { arguments.reduce(source) { |object, argument| object&.send(method, argument) } }
        else
          ->(source) { arguments.reduce(source) { |object, argument| object.send(method, argument) } }
        end
      end

      private

      def validate_config!(config)
        return if config.is_a?(Hash) && config.keys.count { |key| TRANSFORM_TYPES.include?(key) } == 1

        raise ArgumentError, "The transform configuration hash must define exactly one transform type"
      end
    end
  end
end
