# frozen_string_literal: true

module ElevenRb
  # Provides a callback/hook system for monitoring and extending gem behavior
  #
  # @example Setting up callbacks
  #   client = ElevenRb::Client.new(
  #     api_key: "...",
  #     on_error: ->(error:, method:, path:, context:) {
  #       Sentry.capture_exception(error)
  #     }
  #   )
  module Callbacks
    CALLBACK_NAMES = %i[
      on_request
      on_response
      on_error
      on_audio_generated
      on_retry
      on_rate_limit
      on_voice_added
      on_voice_deleted
    ].freeze

    def self.included(base)
      base.attr_accessor(*CALLBACK_NAMES)
    end

    # Trigger a callback if it's configured
    #
    # @param callback_name [Symbol] the name of the callback
    # @param kwargs [Hash] keyword arguments to pass to the callback
    # @return [Object, nil] the return value of the callback, or nil
    def trigger(callback_name, **kwargs)
      callback = send(callback_name)
      return unless callback.respond_to?(:call)

      begin
        callback.call(**kwargs)
      rescue StandardError => e
        # Don't let callback errors break the main flow
        warn "[ElevenRb] Callback error in #{callback_name}: #{e.message}"
        nil
      end
    end
  end
end
