# frozen_string_literal: true

module ElevenRb
  # Main client for interacting with the ElevenLabs API
  #
  # @example Basic usage
  #   client = ElevenRb::Client.new(api_key: "your-api-key")
  #   audio = client.tts.generate("Hello world", voice_id: "abc123")
  #   audio.save_to_file("output.mp3")
  #
  # @example With callbacks
  #   client = ElevenRb::Client.new(
  #     api_key: "your-api-key",
  #     on_error: ->(error:, **) { Sentry.capture_exception(error) },
  #     on_audio_generated: ->(cost_info:, **) { track_cost(cost_info) }
  #   )
  #
  # @example Voice slot management
  #   client.voice_slots.ensure_available(
  #     public_user_id: "abc",
  #     voice_id: "xyz",
  #     name: "Spanish Voice"
  #   )
  class Client
    attr_reader :config, :http_client

    # Initialize a new client
    #
    # @param api_key [String, nil] API key (defaults to ELEVENLABS_API_KEY env var)
    # @param options [Hash] additional configuration options
    # @see Configuration#initialize for all available options
    def initialize(api_key: nil, **options)
      @config = Configuration.new(
        api_key: api_key || ENV.fetch('ELEVENLABS_API_KEY', nil),
        **options
      )
      @http_client = HTTP::Client.new(@config)
    end

    # Check if the client is configured with an API key
    #
    # @return [Boolean]
    def configured?
      config.configured?
    end

    # Voice management resource
    #
    # @return [Resources::Voices]
    def voices
      @voices ||= Resources::Voices.new(http_client)
    end

    # Text-to-speech resource
    #
    # @return [Resources::TextToSpeech]
    def tts
      @tts ||= Resources::TextToSpeech.new(http_client)
    end

    # Voice library resource
    #
    # @return [Resources::VoiceLibrary]
    def voice_library
      @voice_library ||= Resources::VoiceLibrary.new(http_client)
    end

    # Models resource
    #
    # @return [Resources::Models]
    def models
      @models ||= Resources::Models.new(http_client)
    end

    # User/account resource
    #
    # @return [Resources::User]
    def user
      @user ||= Resources::User.new(http_client)
    end

    # Sound effects resource
    #
    # @return [Resources::SoundEffects]
    def sound_effects
      @sound_effects ||= Resources::SoundEffects.new(http_client)
    end

    # Music generation resource
    #
    # @return [Resources::Music]
    def music
      @music ||= Resources::Music.new(http_client)
    end

    # Voice slot manager
    #
    # @return [VoiceSlotManager]
    def voice_slots
      @voice_slots ||= VoiceSlotManager.new(self)
    end

    # Convenience method: generate speech
    #
    # @param text [String] the text to convert
    # @param voice_id [String] the voice ID
    # @param options [Hash] additional options
    # @return [Objects::Audio]
    def generate_speech(text, voice_id:, **options)
      tts.generate(text, voice_id: voice_id, **options)
    end

    # Convenience method: generate sound effect
    #
    # @param text [String] description of the sound effect
    # @param options [Hash] additional options
    # @return [Objects::Audio]
    def generate_sound_effect(text, **options)
      sound_effects.generate(text, **options)
    end

    # Convenience method: generate music
    #
    # @param prompt [String] description of the music to generate
    # @param options [Hash] additional options
    # @return [Objects::Audio]
    def generate_music(prompt, **options)
      music.generate(prompt, **options)
    end

    # Convenience method: stream speech
    #
    # @param text [String] the text to convert
    # @param voice_id [String] the voice ID
    # @param options [Hash] additional options
    # @yield [String] each chunk of audio
    def stream_speech(text, voice_id:, **options, &block)
      tts.stream(text, voice_id: voice_id, **options, &block)
    end

    # Get the TTS adapter for wrapper compatibility
    #
    # @return [TTSAdapter]
    def adapter
      @adapter ||= TTSAdapter.new(self)
    end
  end
end
