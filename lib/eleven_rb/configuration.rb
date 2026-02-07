# frozen_string_literal: true

module ElevenRb
  # Configuration for the ElevenRb client
  #
  # @example Basic configuration
  #   config = ElevenRb::Configuration.new(api_key: "your-api-key")
  #
  # @example Full configuration with callbacks
  #   config = ElevenRb::Configuration.new(
  #     api_key: "your-api-key",
  #     timeout: 60,
  #     on_error: ->(error:, **) { Sentry.capture_exception(error) }
  #   )
  class Configuration
    include Callbacks

    DEFAULTS = {
      base_url: 'https://api.elevenlabs.io/v1',
      timeout: 120,
      open_timeout: 10,
      max_retries: 3,
      retry_delay: 1.0,
      retry_statuses: [429, 500, 502, 503, 504].freeze
    }.freeze

    attr_accessor :api_key, :base_url, :timeout, :open_timeout,
                  :max_retries, :retry_delay, :retry_statuses,
                  :logger

    # Initialize a new configuration
    #
    # @param options [Hash] configuration options
    # @option options [String] :api_key ElevenLabs API key (required)
    # @option options [String] :base_url API base URL (default: https://api.elevenlabs.io/v1)
    # @option options [Integer] :timeout Request timeout in seconds (default: 120)
    # @option options [Integer] :open_timeout Connection timeout in seconds (default: 10)
    # @option options [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option options [Float] :retry_delay Base delay between retries in seconds (default: 1.0)
    # @option options [Array<Integer>] :retry_statuses HTTP status codes to retry (default: [429, 500, 502, 503, 504])
    # @option options [Logger] :logger Logger instance for debug output
    # @option options [Proc] :on_request Callback before each request
    # @option options [Proc] :on_response Callback after successful response
    # @option options [Proc] :on_error Callback when an error occurs
    # @option options [Proc] :on_audio_generated Callback after TTS generation
    # @option options [Proc] :on_retry Callback before retry attempt
    # @option options [Proc] :on_rate_limit Callback when rate limited
    # @option options [Proc] :on_voice_added Callback when voice added
    # @option options [Proc] :on_voice_deleted Callback when voice deleted
    def initialize(**options)
      # Set defaults
      DEFAULTS.each { |k, v| send("#{k}=", v) }

      # Override with provided options (including callbacks)
      options.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    # Check if the configuration has an API key
    #
    # @return [Boolean]
    def configured?
      !api_key.nil? && !api_key.to_s.empty?
    end

    # Validate the configuration
    #
    # @raise [Errors::ConfigurationError] if configuration is invalid
    # @return [true]
    def validate!
      if api_key.nil? || api_key.to_s.empty?
        raise Errors::ConfigurationError,
              'API key is required. Set via api_key option or ELEVENLABS_API_KEY environment variable.'
      end

      true
    end

    # Return a hash representation (with API key redacted)
    #
    # @return [Hash]
    def to_h
      {
        api_key: api_key ? '[REDACTED]' : nil,
        base_url: base_url,
        timeout: timeout,
        open_timeout: open_timeout,
        max_retries: max_retries,
        retry_delay: retry_delay
      }
    end
  end
end
