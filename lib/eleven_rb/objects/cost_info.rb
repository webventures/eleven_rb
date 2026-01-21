# frozen_string_literal: true

module ElevenRb
  module Objects
    # Cost information for TTS generation
    class CostInfo
      attr_reader :character_count, :voice_id, :model_id

      # Approximate cost per 1000 characters by model
      # These are estimates and may vary by subscription tier
      COST_PER_1K_CHARS = {
        "eleven_monolingual_v1" => 0.30,
        "eleven_multilingual_v1" => 0.30,
        "eleven_multilingual_v2" => 0.30,
        "eleven_turbo_v2" => 0.18,
        "eleven_turbo_v2_5" => 0.18,
        "eleven_english_sts_v2" => 0.30,
        "eleven_flash_v2" => 0.10,
        "eleven_flash_v2_5" => 0.10
      }.freeze

      DEFAULT_COST_PER_1K = 0.30

      # Initialize cost info
      #
      # @param text [String] the text being converted
      # @param voice_id [String] the voice ID
      # @param model_id [String] the model ID
      def initialize(text:, voice_id:, model_id:)
        @character_count = text.length
        @voice_id = voice_id
        @model_id = model_id
      end

      # Get estimated cost in USD
      #
      # @return [Float]
      def estimated_cost
        rate = COST_PER_1K_CHARS[model_id] || DEFAULT_COST_PER_1K
        (character_count / 1000.0 * rate).round(4)
      end

      # Get cost per character for this model
      #
      # @return [Float]
      def cost_per_character
        rate = COST_PER_1K_CHARS[model_id] || DEFAULT_COST_PER_1K
        rate / 1000.0
      end

      # Check if this is a turbo/cheaper model
      #
      # @return [Boolean]
      def turbo_model?
        model_id&.include?("turbo") || model_id&.include?("flash")
      end

      # Convert to hash
      #
      # @return [Hash]
      def to_h
        {
          character_count: character_count,
          voice_id: voice_id,
          model_id: model_id,
          estimated_cost: estimated_cost,
          cost_per_character: cost_per_character
        }
      end
    end
  end
end
