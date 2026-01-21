# frozen_string_literal: true

module ElevenRb
  module Objects
    # Represents user subscription information
    class Subscription < Base
      attribute :tier
      attribute :character_count
      attribute :character_limit
      attribute :voice_limit
      attribute :professional_voice_limit
      attribute :can_extend_character_limit, type: :boolean
      attribute :allowed_to_extend_character_limit, type: :boolean
      attribute :next_character_count_reset_unix
      attribute :can_extend_voice_limit, type: :boolean
      attribute :can_use_instant_voice_cloning, type: :boolean
      attribute :can_use_professional_voice_cloning, type: :boolean
      attribute :currency
      attribute :status

      # Get the number of voice slots currently used
      # Note: This requires checking voices.list count
      #
      # @return [Integer, nil]
      attr_accessor :voice_slots_used

      # Set voice slots used (called by VoiceSlotManager)
      #
      # @param count [Integer]

      # Get available voice slots
      #
      # @return [Integer, nil]
      def voice_slots_available
        return nil unless voice_limit && voice_slots_used

        voice_limit - voice_slots_used
      end

      # Check if voice slots are full
      #
      # @return [Boolean]
      def voice_slots_full?
        return false unless voice_slots_available

        voice_slots_available <= 0
      end

      # Get remaining characters
      #
      # @return [Integer]
      def characters_remaining
        return 0 unless character_limit && character_count

        character_limit - character_count
      end

      # Get percentage of characters used
      #
      # @return [Float]
      def characters_used_percentage
        return 0.0 unless character_limit&.positive?

        (character_count.to_f / character_limit * 100).round(1)
      end

      # Get next reset time as Time object
      #
      # @return [Time, nil]
      def next_reset_at
        return nil unless next_character_count_reset_unix

        Time.at(next_character_count_reset_unix)
      end

      # Check if subscription is active
      #
      # @return [Boolean]
      def active?
        status == 'active'
      end

      # Check if this is a free tier
      #
      # @return [Boolean]
      def free?
        tier&.downcase == 'free'
      end
    end
  end
end
