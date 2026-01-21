# frozen_string_literal: true

module ElevenRb
  # Adapter for potential future voiceagent wrapper gem
  #
  # Implements a standard interface that other TTS provider gems could follow,
  # allowing a wrapper gem to provide a unified API across providers.
  #
  # @example Using the adapter directly
  #   adapter = ElevenRb::TTSAdapter.new
  #   audio = adapter.generate("Hello", voice_id: "abc123")
  #
  # @example With a hypothetical wrapper gem
  #   agent = VoiceAgent.new
  #   agent.register(:elevenlabs, ElevenRb::TTSAdapter.new)
  #   agent.generate("Hello", provider: :elevenlabs, voice_id: "abc123")
  class TTSAdapter
    attr_reader :client

    # Initialize the adapter
    #
    # @param client [Client, nil] optional client (creates one if not provided)
    def initialize(client = nil)
      @client = client || Client.new
    end

    # Provider identifier
    #
    # @return [Symbol]
    def provider_name
      :elevenlabs
    end

    # List available voices
    #
    # @return [Array<Hash>] normalized voice data
    def list_voices
      @client.voices.list.map do |voice|
        {
          provider: :elevenlabs,
          voice_id: voice.voice_id,
          name: voice.name,
          gender: voice.gender,
          language: voice.language,
          accent: voice.accent,
          category: voice.category,
          preview_url: voice.preview_url,
          metadata: voice.to_h
        }
      end
    end

    # Generate audio from text
    #
    # @param text [String] the text to convert
    # @param voice_id [String] the voice ID
    # @param options [Hash] additional options
    # @return [Objects::Audio]
    def generate(text, voice_id:, **options)
      @client.tts.generate(text, voice_id: voice_id, **options)
    end

    # Stream audio from text
    #
    # @param text [String] the text to convert
    # @param voice_id [String] the voice ID
    # @param options [Hash] additional options
    # @yield [String] each chunk of audio
    def stream(text, voice_id:, **options, &block)
      @client.tts.stream(text, voice_id: voice_id, **options, &block)
    end

    # Check if streaming is supported
    #
    # @return [Boolean]
    def supports_streaming?
      true
    end

    # Get available models
    #
    # @return [Array<Hash>] normalized model data
    def list_models
      @client.models.list.map do |model|
        {
          provider: :elevenlabs,
          model_id: model.model_id,
          name: model.name,
          multilingual: model.multilingual?,
          languages: model.supported_language_codes,
          metadata: model.to_h
        }
      end
    end

    # Get subscription/quota info
    #
    # @return [Hash] normalized quota data
    def quota
      sub = @client.user.subscription
      {
        provider: :elevenlabs,
        tier: sub.tier,
        characters_used: sub.character_count,
        characters_limit: sub.character_limit,
        characters_remaining: sub.characters_remaining,
        resets_at: sub.next_reset_at
      }
    end

    # Search voice library
    #
    # @param options [Hash] search options
    # @return [Array<Hash>] normalized voice data
    def search_voices(**options)
      @client.voice_library.search(**options).map do |voice|
        {
          provider: :elevenlabs,
          voice_id: voice.voice_id,
          public_owner_id: voice.public_owner_id,
          name: voice.name,
          gender: voice.gender,
          language: voice.language,
          accent: voice.accent,
          metadata: voice.to_h
        }
      end
    end

    # Ensure a library voice is available (for voice slot management)
    #
    # @param public_user_id [String]
    # @param voice_id [String]
    # @param name [String]
    # @return [Hash] normalized voice data
    def ensure_voice_available(public_user_id:, voice_id:, name:)
      voice = @client.voice_slots.ensure_available(
        public_user_id: public_user_id,
        voice_id: voice_id,
        name: name
      )

      {
        provider: :elevenlabs,
        voice_id: voice.voice_id,
        name: voice.name,
        metadata: voice.to_h
      }
    end
  end
end
