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
    # A callback that names its keywords explicitly (no `**rest`) receives only
    # the keywords it declares, so callbacks written before a keyword was added
    # (e.g. `request_id:` on on_audio_generated in 1.1.0) keep working.
    #
    # @param callback_name [Symbol] the name of the callback
    # @param kwargs [Hash] keyword arguments to pass to the callback
    # @return [Object, nil] the return value of the callback, or nil
    def trigger(callback_name, **kwargs)
      callback = send(callback_name)
      return unless callback.respond_to?(:call)

      begin
        callback.call(**accepted_callback_kwargs(callback, kwargs))
      rescue StandardError => e
        # Don't let callback errors break the main flow
        warn "[ElevenRb] Callback error in #{callback_name}: #{e.message}"
        nil
      end
    end

    private

    def accepted_callback_kwargs(callback, kwargs)
      params = callback_parameters(callback)
      return kwargs if params.nil? || params.any? { |type, _| type == :keyrest }

      accepted = params.filter_map { |type, name| name if %i[key keyreq].include?(type) }
      return kwargs if accepted.empty?

      kwargs.slice(*accepted)
    end

    def callback_parameters(callback)
      return callback.parameters if callback.respond_to?(:parameters)

      callback.method(:call).parameters
    rescue NameError
      nil
    end
  end
end
