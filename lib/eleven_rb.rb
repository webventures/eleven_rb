# frozen_string_literal: true

require 'httparty'
require 'json'
require 'base64'

# ElevenRb - A Ruby client for the ElevenLabs Text-to-Speech API
#
# @example Basic usage
#   client = ElevenRb::Client.new(api_key: "your-api-key")
#   audio = client.tts.generate("Hello world", voice_id: "abc123")
#   audio.save_to_file("output.mp3")
#
# @example Using the module-level client
#   ElevenRb.client.tts.generate("Hello", voice_id: "abc123")
#
# @example Voice slot management
#   client.voice_slots.ensure_available(
#     public_user_id: "owner123",
#     voice_id: "voice456",
#     name: "My Voice"
#   )
module ElevenRb
  class << self
    # Get a shared client instance
    #
    # @param api_key [String, nil] optional API key
    # @return [Client]
    def client(api_key: nil)
      @client ||= Client.new(api_key: api_key)
    end

    # Configure the shared client
    #
    # @yield [Configuration] the configuration object
    # @return [Client]
    def configure
      config = Configuration.new(api_key: ENV.fetch('ELEVENLABS_API_KEY', nil))
      yield config if block_given?
      config.validate!
      @client = Client.new(**config_to_options(config))
    end

    # Reset the shared client
    #
    # @return [void]
    def reset!
      @client = nil
    end

    private

    def config_to_options(config)
      {
        api_key: config.api_key,
        base_url: config.base_url,
        timeout: config.timeout,
        open_timeout: config.open_timeout,
        max_retries: config.max_retries,
        retry_delay: config.retry_delay,
        retry_statuses: config.retry_statuses,
        logger: config.logger,
        on_request: config.on_request,
        on_response: config.on_response,
        on_error: config.on_error,
        on_audio_generated: config.on_audio_generated,
        on_retry: config.on_retry,
        on_rate_limit: config.on_rate_limit,
        on_voice_added: config.on_voice_added,
        on_voice_deleted: config.on_voice_deleted
      }.compact
    end
  end
end

# Core modules
require_relative 'eleven_rb/version'
require_relative 'eleven_rb/errors'
require_relative 'eleven_rb/callbacks'
require_relative 'eleven_rb/instrumentation'
require_relative 'eleven_rb/configuration'

# HTTP layer
require_relative 'eleven_rb/http/client'

# Response objects
require_relative 'eleven_rb/objects/base'
require_relative 'eleven_rb/objects/voice_settings'
require_relative 'eleven_rb/objects/voice'
require_relative 'eleven_rb/objects/audio'
require_relative 'eleven_rb/objects/model'
require_relative 'eleven_rb/objects/subscription'
require_relative 'eleven_rb/objects/user_info'
require_relative 'eleven_rb/objects/library_voice'
require_relative 'eleven_rb/objects/cost_info'

# Collections
require_relative 'eleven_rb/collections/base'
require_relative 'eleven_rb/collections/voice_collection'
require_relative 'eleven_rb/collections/library_voice_collection'

# Resources
require_relative 'eleven_rb/resources/base'
require_relative 'eleven_rb/resources/voices'
require_relative 'eleven_rb/resources/text_to_speech'
require_relative 'eleven_rb/resources/voice_library'
require_relative 'eleven_rb/resources/models'
require_relative 'eleven_rb/resources/user'

# High-level components
require_relative 'eleven_rb/voice_slot_manager'
require_relative 'eleven_rb/tts_adapter'
require_relative 'eleven_rb/client'
