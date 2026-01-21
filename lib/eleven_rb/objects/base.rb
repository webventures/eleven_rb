# frozen_string_literal: true

module ElevenRb
  module Objects
    # Base class for all response objects
    #
    # Provides attribute accessors and common functionality for
    # parsing API responses into structured objects.
    class Base
      class << self
        # Create an object from an API response hash
        #
        # @param response [Hash] the API response
        # @return [Base] the object instance
        def from_response(response)
          new(response)
        end

        # Define an attribute accessor
        #
        # @param name [Symbol] the attribute name
        # @param key [String, nil] the JSON key (defaults to name.to_s)
        # @param type [Class, Symbol, nil] optional type for conversion
        def attribute(name, key: nil, type: nil)
          key ||= name.to_s

          define_method(name) do
            value = @attributes[key]
            return nil if value.nil?

            case type
            when :boolean
              !!value
            when Class
              if value.is_a?(Array)
                value.map { |v| type.from_response(v) }
              else
                type.from_response(value)
              end
            else
              value
            end
          end
        end
      end

      # Initialize with attributes hash
      #
      # @param attributes [Hash] the attributes
      def initialize(attributes = {})
        @attributes = attributes || {}
      end

      # Return raw attributes hash
      #
      # @return [Hash]
      def to_h
        @attributes.dup
      end

      # Access raw attribute by key
      #
      # @param key [String, Symbol] the attribute key
      # @return [Object, nil]
      def [](key)
        @attributes[key.to_s]
      end

      # Check if attribute exists
      #
      # @param key [String, Symbol] the attribute key
      # @return [Boolean]
      def key?(key)
        @attributes.key?(key.to_s)
      end

      # Inspect the object
      #
      # @return [String]
      def inspect
        attrs = @attributes.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
        "#<#{self.class.name} #{attrs}>"
      end
    end
  end
end
