# frozen_string_literal: true

module ElevenRb
  module Objects
    # Voice settings for TTS generation
    class VoiceSettings < Base
      attribute :stability
      attribute :similarity_boost
      attribute :style
      attribute :use_speaker_boost, type: :boolean

      # Default settings for TTS generation
      DEFAULTS = {
        stability: 0.5,
        similarity_boost: 0.75,
        style: 0.0,
        use_speaker_boost: true
      }.freeze

      # Create settings with defaults merged in
      #
      # @param overrides [Hash] settings to override defaults
      # @return [VoiceSettings]
      def self.with_defaults(overrides = {})
        from_response(DEFAULTS.merge(overrides))
      end

      # Voice-setting keys the capability table knows about. Only these can be
      # dropped for a model; any other key is passed through untouched so a
      # future API field is never swallowed.
      KNOWN_KEYS = ModelCapabilities::ALL_VOICE_SETTINGS

      # Build the voice_settings hash a model actually honours
      #
      # Starts from DEFAULTS filtered to the model's supported keys and merges the
      # overrides (keys symbolized). Known keys the model does not support are
      # dropped; unknown keys pass through after the supported ones, in the
      # caller's order; nil values are removed. Only non-nil override keys count
      # as dropped: defaults the model does not take are filtered silently.
      #
      # @example
      #   VoiceSettings.for_model('eleven_multilingual_v2')
      #   # => [{ stability: 0.5, similarity_boost: 0.75, style: 0.0, use_speaker_boost: true }, []]
      #   VoiceSettings.for_model('eleven_v4', speed: 1.1)
      #   # => [{ stability: 0.5, similarity_boost: 0.75 }, [:speed]]
      #
      # @param model_id [String] the model ID
      # @param overrides [Hash] caller settings (String or Symbol keys)
      # @return [Array(Hash, Array<Symbol>)] the settings hash and the dropped override keys
      def self.for_model(model_id, overrides = {})
        supported = ModelCapabilities.supported_voice_settings(model_id)
        requested = (overrides || {}).to_h.transform_keys(&:to_sym)

        dropped = requested.compact.keys & (KNOWN_KEYS - supported)
        unknown = requested.except(*KNOWN_KEYS)
        settings = DEFAULTS.slice(*supported).merge(requested.slice(*supported)).merge(unknown).compact

        [settings, dropped]
      end

      # Convert to hash suitable for API request
      #
      # @return [Hash]
      def to_api_hash
        {
          stability: stability,
          similarity_boost: similarity_boost,
          style: style,
          use_speaker_boost: use_speaker_boost
        }.compact
      end
    end
  end
end
