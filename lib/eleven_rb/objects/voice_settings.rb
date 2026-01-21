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
