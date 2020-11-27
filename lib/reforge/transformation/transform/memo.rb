# frozen_string_literal: true

module Reforge
  class Transformation
    class Transform
      class Memo
        CONSTANT_TRANSFORM = ->(_source) { :constant }.freeze
        IDENTITY_TRANSFORM = ->(source) { source }.freeze

        # TODO: here we code to the least common denominator: everything is a proc. This likely works slower than
        # something specialized to each individual case This could be of concern since these will be called
        # per-transform, per-source
        def self.from(memoize)
          if memoize.is_a?(Hash) # rubocop:disable Style/CaseLikeIf:
            Memo.new(memoize[:by])
          elsif memoize == :first
            Memo.new(CONSTANT_TRANSFORM)
          elsif memoize == true
            Memo.new(IDENTITY_TRANSFORM)
          else
            raise ArgumentError, "The memoize option should be true, :first, or a valid configuration hash"
          end
        end

        def initialize(key_transform)
          @memo = {}
          @key_transform = Transform.new(key_transform)
        rescue ArgumentError
          # TRICKY: Transform didn't like key_transform, but we want to raise an error specific to Memo, not the one
          # directly from Transform
          raise ArgumentError, "The memoize option should be true, :first, or a valid configuration hash"
        end

        def [](source)
          key = @key_transform.call(source)
          @memo[key]
        end

        def []=(source, value)
          key = @key_transform.call(source)
          @memo[key] = value
        end
      end
    end
  end
end
