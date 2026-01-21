# frozen_string_literal: true

module ElevenRb
  module Resources
    # Base class for API resources
    class Base
      attr_reader :http_client

      # Initialize resource
      #
      # @param http_client [HTTP::Client]
      def initialize(http_client)
        @http_client = http_client
      end

      private

      # Make a GET request
      #
      # @param path [String]
      # @param params [Hash]
      # @return [Hash, Array]
      def get(path, params = {})
        http_client.get(path, params)
      end

      # Make a POST request
      #
      # @param path [String]
      # @param body [Hash]
      # @param response_type [Symbol]
      # @return [Hash, Array, String]
      def post(path, body = {}, response_type: :json)
        http_client.post(path, body, response_type: response_type)
      end

      # Make a DELETE request
      #
      # @param path [String]
      # @return [Hash]
      def delete(path)
        http_client.delete(path)
      end

      # Make a binary POST request
      #
      # @param path [String]
      # @param body [Hash]
      # @return [String]
      def post_binary(path, body = {})
        http_client.post(path, body, response_type: :binary)
      end

      # Make a streaming POST request
      #
      # @param path [String]
      # @param body [Hash]
      # @yield [String] chunk
      def post_stream(path, body = {}, &block)
        http_client.post_stream(path, body, &block)
      end

      # Make a multipart POST request
      #
      # @param path [String]
      # @param params [Hash]
      # @return [Hash]
      def post_multipart(path, params)
        http_client.post_multipart(path, params)
      end

      # Validate presence of a value
      #
      # @param value [Object]
      # @param name [String]
      # @raise [Errors::ValidationError]
      def validate_presence!(value, name)
        return unless value.nil? || (value.respond_to?(:empty?) && value.empty?)

        raise Errors::ValidationError, "#{name} cannot be blank"
      end
    end
  end
end
