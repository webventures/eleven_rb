# frozen_string_literal: true

module ElevenRb
  module Collections
    # Base class for collections of objects
    #
    # Provides Enumerable support and pagination helpers
    class Base
      include Enumerable

      attr_reader :items, :raw_response

      # Create collection from API response
      #
      # @param response [Hash] the API response
      # @return [Base]
      def self.from_response(response)
        new(response)
      end

      # Initialize collection
      #
      # @param response [Hash] the API response
      def initialize(response)
        @raw_response = response
        @items = parse_items(response)
      end

      # Iterate over items
      #
      # @yield [Object] each item
      def each(&block)
        items.each(&block)
      end

      # Get item by index
      #
      # @param index [Integer]
      # @return [Object, nil]
      def [](index)
        items[index]
      end

      # Get collection size
      #
      # @return [Integer]
      def size
        items.size
      end
      alias length size
      alias count size

      # Check if collection is empty
      #
      # @return [Boolean]
      def empty?
        items.empty?
      end

      # Get first item
      #
      # @return [Object, nil]
      def first
        items.first
      end

      # Get last item
      #
      # @return [Object, nil]
      def last
        items.last
      end

      # Convert to array
      #
      # @return [Array]
      def to_a
        items.dup
      end

      private

      # Override in subclasses to parse items
      #
      # @param response [Hash] the API response
      # @return [Array]
      def parse_items(response)
        raise NotImplementedError, 'Subclasses must implement #parse_items'
      end
    end
  end
end
