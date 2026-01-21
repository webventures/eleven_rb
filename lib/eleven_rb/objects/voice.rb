# frozen_string_literal: true

module ElevenRb
  module Objects
    # Represents an ElevenLabs voice
    class Voice < Base
      attribute :voice_id
      attribute :name
      attribute :description
      attribute :category
      attribute :preview_url
      attribute :labels
      attribute :settings, type: VoiceSettings
      attribute :samples
      attribute :sharing
      attribute :high_quality_base_model_ids
      attribute :safety_control

      # Get the gender from labels
      #
      # @return [String, nil]
      def gender
        labels&.dig('gender')
      end

      # Get the accent from labels
      #
      # @return [String, nil]
      def accent
        labels&.dig('accent')
      end

      # Get the language from labels
      #
      # @return [String, nil]
      def language
        labels&.dig('language')
      end

      # Get the age from labels
      #
      # @return [String, nil]
      def age
        labels&.dig('age')
      end

      # Get the use case from labels
      #
      # @return [String, nil]
      def use_case
        labels&.dig('use_case')
      end

      # Check if this voice is banned
      #
      # @return [Boolean]
      def banned?
        safety_control == 'BAN'
      end

      # Provider identifier for wrapper compatibility
      #
      # @return [Symbol]
      def provider
        :elevenlabs
      end

      # Alias for voice_id for wrapper compatibility
      #
      # @return [String]
      def provider_voice_id
        voice_id
      end

      # Human-readable display name with metadata
      #
      # @return [String]
      def display_name
        parts = [name]
        parts << "(#{gender})" if gender
        parts << "- #{accent || language}" if accent || language
        parts.join(' ')
      end
    end
  end
end
