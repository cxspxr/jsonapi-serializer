require 'jsonapi/serializer/base'
require 'jsonapi/serializer/core'
require 'jsonapi/serializer/dsl'
require 'jsonapi/serializer/errors'
require 'jsonapi/serializer/trackable'

module JSONAPI
  module Serializer
    extend Trackable

    # Self registers any inherited/extended class to keep track of it
    #
    # @return nothing
    def self.included(base)
      super

      register_serializer(base)

      base.class_eval do
        include ::JSONAPI::Serializer::Base
        extend ::JSONAPI::Serializer::DSL
        extend ::JSONAPI::Serializer::Core
      end
    end

    # Serializes an object or a collection
    #
    # The `options` are passed to the serializer instance and follow the
    # same purpose.
    #
    # The only extra option is the `options[:serializers]`
    # one can use to pass a mapping of object to serializer classes to
    # be strict about how each object is serialized.
    #
    # @param object_or_collection [Object] to be serialized
    # @param options [Hash] serialization parameters
    # @return [Hash] of serialized JSONAPI data
    def self.serialize(object_or_collection, options: nil)
      options ||= {}
      options[:is_collection] = is_collection?(
        object_or_collection, force: options[:is_collection]
      )

      if options[:is_collection]
        serializer = for_object(
          object_or_collection.first,
          options.delete(:serializers)
        )
      else
        serializer = for_object(
          object_or_collection,
          options.delete(:serializers)
        )
      end

      serializer.new(object_or_collection, options).serializable_hash
    end

    # Detects a collection/enumerable
    #
    # @param resource [Object] to detect
    # @return [TrueClass] on a successful detection
    def self.is_collection?(resource, force: nil)
      return force unless force.nil?

      # Rails 4 does not use [Enumerable]...
      active_record = defined?(ActiveRecord::Relation)
      return true if active_record && resource.is_a?(ActiveRecord::Relation)

      resource.is_a?(Enumerable) && !resource.respond_to?(:each_pair)
    end
  end
end
