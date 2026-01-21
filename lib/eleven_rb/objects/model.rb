# frozen_string_literal: true

module ElevenRb
  module Objects
    # Represents an ElevenLabs TTS model
    class Model < Base
      attribute :model_id
      attribute :name
      attribute :description
      attribute :can_be_finetuned, type: :boolean
      attribute :can_do_text_to_speech, type: :boolean
      attribute :can_do_voice_conversion, type: :boolean
      attribute :can_use_style, type: :boolean
      attribute :can_use_speaker_boost, type: :boolean
      attribute :serves_pro_voices, type: :boolean
      attribute :token_cost_factor
      attribute :languages
      attribute :max_characters_request_free_user
      attribute :max_characters_request_subscribed_user
      attribute :concurrency_group

      # Check if this model supports a given language
      #
      # @param language_code [String] ISO language code
      # @return [Boolean]
      def supports_language?(language_code)
        return false unless languages

        languages.any? { |l| l["language_id"] == language_code }
      end

      # Get list of supported language codes
      #
      # @return [Array<String>]
      def supported_language_codes
        return [] unless languages

        languages.map { |l| l["language_id"] }
      end

      # Check if this is a multilingual model
      #
      # @return [Boolean]
      def multilingual?
        name&.downcase&.include?("multilingual") || supported_language_codes.size > 1
      end

      # Check if this is a turbo/fast model
      #
      # @return [Boolean]
      def turbo?
        name&.downcase&.include?("turbo") || model_id&.include?("turbo")
      end
    end
  end
end
