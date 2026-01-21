# frozen_string_literal: true

require "httparty"
require "json"

module ElevenRb
  module HTTP
    # HTTP client for making requests to the ElevenLabs API
    class Client
      include HTTParty

      attr_reader :config

      # Initialize the HTTP client
      #
      # @param config [Configuration] the configuration object
      def initialize(config)
        @config = config
      end

      # Make a GET request
      #
      # @param path [String] the API path
      # @param params [Hash] query parameters
      # @return [Hash, Array] parsed JSON response
      def get(path, params = {})
        request(:get, path, params: params)
      end

      # Make a POST request
      #
      # @param path [String] the API path
      # @param body [Hash] request body
      # @param response_type [Symbol] :json or :binary
      # @return [Hash, Array, String] parsed response
      def post(path, body = {}, response_type: :json)
        request(:post, path, body: body, response_type: response_type)
      end

      # Make a DELETE request
      #
      # @param path [String] the API path
      # @return [Hash] parsed JSON response
      def delete(path)
        request(:delete, path)
      end

      # Make a multipart POST request (for file uploads)
      #
      # @param path [String] the API path
      # @param params [Hash] form parameters including files
      # @return [Hash] parsed JSON response
      def post_multipart(path, params)
        request(:post, path, body: params, multipart: true)
      end

      # Make a streaming POST request
      #
      # @param path [String] the API path
      # @param body [Hash] request body
      # @yield [String] yields each chunk of data
      # @return [void]
      def post_stream(path, body = {}, &block)
        request(:post, path, body: body, stream: true, &block)
      end

      private

      def request(method, path, body: nil, params: nil, response_type: :json, multipart: false, stream: false, attempt: 1, &block)
        url = "#{config.base_url}#{path}"
        start_time = Time.now

        # Trigger before request callback
        config.trigger(:on_request, method: method, path: path, body: sanitize_body_for_logging(body))

        begin
          response = execute_request(method, url, body, params, multipart, stream, &block)
          duration = ((Time.now - start_time) * 1000).round(2)

          # For streaming, we've already processed the data
          return nil if stream

          # Trigger after response callback
          config.trigger(:on_response, method: method, path: path, response: response, duration: duration)

          # Return binary data directly
          return response.body if response_type == :binary && response.success?

          handle_response(response)
        rescue Errors::RateLimitError => e
          config.trigger(:on_rate_limit, retry_after: e.retry_after, error: e)
          handle_retry(e, method, path, body, params, response_type, multipart, stream, attempt, &block)
        rescue Errors::ServerError => e
          handle_retry(e, method, path, body, params, response_type, multipart, stream, attempt, &block)
        rescue Errors::Base => e
          config.trigger(:on_error, error: e, method: method, path: path, context: { body: sanitize_body_for_logging(body) })
          raise
        rescue StandardError => e
          wrapped_error = wrap_error(e)
          config.trigger(:on_error, error: wrapped_error, method: method, path: path, context: { body: sanitize_body_for_logging(body) })
          raise wrapped_error
        end
      end

      def execute_request(method, url, body, params, multipart, stream, &block)
        options = build_options(body, params, multipart, stream, &block)

        case method
        when :get
          self.class.get(url, options)
        when :post
          self.class.post(url, options)
        when :delete
          self.class.delete(url, options)
        else
          raise ArgumentError, "Unknown HTTP method: #{method}"
        end
      end

      def build_options(body, params, multipart, stream, &block)
        options = {
          headers: headers(multipart),
          timeout: config.timeout,
          open_timeout: config.open_timeout
        }

        options[:query] = params if params && !params.empty?

        if body && !body.empty?
          if multipart
            options[:body] = build_multipart_body(body)
          else
            options[:body] = body.to_json
          end
        end

        if stream && block_given?
          options[:stream_body] = true
          options[:on_data] = block
        end

        options
      end

      def headers(multipart = false)
        h = {
          "xi-api-key" => config.api_key,
          "Accept" => "application/json"
        }
        h["Content-Type"] = "application/json" unless multipart
        h
      end

      def build_multipart_body(params)
        body = {}

        params.each do |key, value|
          case key.to_sym
          when :files
            # Handle file array
            Array(value).each_with_index do |file, index|
              body["files[#{index}]"] = file
            end
          else
            body[key.to_s] = value
          end
        end

        body
      end

      def handle_response(response)
        return parse_json(response.body) if response.success?

        handle_error_response(response)
      end

      def handle_error_response(response)
        status = response.code
        body = parse_error_body(response.body)
        message = extract_error_message(body)

        error_class = case status
                      when 400 then Errors::ValidationError
                      when 401 then Errors::AuthenticationError
                      when 403 then Errors::ForbiddenError
                      when 404 then Errors::NotFoundError
                      when 422 then Errors::UnprocessableError
                      when 429 then Errors::RateLimitError
                      when 500..599 then Errors::ServerError
                      else Errors::APIError
                      end

        error_kwargs = {
          http_status: status,
          response_body: body,
          error_code: body["error_code"]
        }

        if error_class == Errors::RateLimitError
          retry_after = response.headers["retry-after"]&.to_i
          error_kwargs[:retry_after] = retry_after
        end

        raise error_class.new(message, **error_kwargs)
      end

      def handle_retry(error, method, path, body, params, response_type, multipart, stream, attempt, &block)
        if attempt > config.max_retries || !config.retry_statuses.include?(error.http_status)
          raise error
        end

        delay = if error.is_a?(Errors::RateLimitError) && error.retry_after
                  error.retry_after
                else
                  config.retry_delay * attempt
                end

        config.trigger(:on_retry, error: error, attempt: attempt, max_attempts: config.max_retries, delay: delay)

        sleep(delay)

        request(method, path, body: body, params: params, response_type: response_type, multipart: multipart, stream: stream, attempt: attempt + 1, &block)
      end

      def wrap_error(error)
        case error
        when Timeout::Error, Net::OpenTimeout
          Errors::TimeoutError.new(error.message)
        when SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET
          Errors::ConnectionError.new(error.message)
        else
          Errors::APIError.new(error.message)
        end
      end

      def parse_json(body)
        return {} if body.nil? || body.empty?

        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def parse_error_body(body)
        parse_json(body)
      end

      def extract_error_message(body)
        detail = body["detail"]
        case detail
        when Hash
          detail["message"] || detail["status"] || detail.to_s
        when String
          detail
        else
          body["message"] || body["error"] || "Unknown error"
        end
      end

      def sanitize_body_for_logging(body)
        return nil if body.nil?

        # Remove any sensitive data or large binary content
        if body.is_a?(Hash)
          body.transform_values do |v|
            v.is_a?(File) ? "[FILE: #{v.path}]" : v
          end
        else
          body
        end
      end
    end
  end
end
