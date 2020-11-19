# frozen_string_literal: true

module Reforge
  class Transform
    module Helpers
      TRANSFORM_PROC_FACTORIES = {
        attribute: ->(*attributes, **opts) { attribute_transform_for(*attributes, **opts) },
        key: ->(*keys, **opts) { key_transform_for(*keys, **opts) },
        value: ->(value, **_opts) { value_transform_for(value) }
      }.freeze
      TRANSFORM_TYPES = TRANSFORM_PROC_FACTORIES.keys.freeze

      private_class_method def self.attribute_transform_for(*attributes, allow_nil: false)
        recursive_method_call(:send, *attributes, allow_nil: allow_nil)
      end

      private_class_method def self.key_transform_for(*keys, allow_nil: false)
        recursive_method_call(:[], *keys, allow_nil: allow_nil)
      end

      private_class_method def self.recursive_method_call(method, *arguments, allow_nil: false)
        if allow_nil
          ->(source) { arguments.reduce(source) { |object, argument| object&.send(method, argument) } }
        else
          ->(source) { arguments.reduce(source) { |object, argument| object.send(method, argument) } }
        end
      end

      private_class_method def self.value_transform_for(value)
        ->(_source) { value }
      end

      def proc_from_configuration_hash(config)
        validate_config!(config)

        type = config.keys.detect { |key| TRANSFORM_TYPES.include?(key) }
        args = config.delete(type)

        TRANSFORM_PROC_FACTORIES[type].call(*args, **config)
      end

      private

      def validate_config!(config)
        return if config.is_a?(Hash) && config.keys.count { |key| TRANSFORM_TYPES.include?(key) } == 1

        raise ArgumentError, "The transform configuration hash is not a valid"
      end
    end
  end
end
