# frozen_string_literal: true

module ElevenRb
  module Objects
    # Represents a voice from the shared voice library
    class LibraryVoice < Base
      attribute :voice_id
      attribute :public_owner_id
      attribute :name
      attribute :description
      attribute :category
      attribute :preview_url
      attribute :gender
      attribute :age
      attribute :accent
      attribute :language
      attribute :locale
      attribute :use_cases
      attribute :notice_period
      attribute :rate
      attribute :cloned_by_count
      attribute :usage_character_count_1d
      attribute :usage_character_count_7d
      attribute :usage_character_count_30d
      attribute :free_users_allowed, type: :boolean
      attribute :live_moderation_enabled, type: :boolean
      attribute :verified, type: :boolean

      # Get parameters needed to add this voice to account
      #
      # @return [Hash]
      def add_params
        {
          public_user_id: public_owner_id,
          voice_id: voice_id,
          name: name
        }
      end

      # Human-readable display name with metadata
      #
      # @return [String]
      def display_name
        parts = [name]
        parts << "(#{gender})" if gender
        parts << "- #{accent || language}" if accent || language
        parts.join(" ")
      end

      # Check if this voice is popular (high usage)
      #
      # @param threshold [Integer] minimum usage count
      # @return [Boolean]
      def popular?(threshold: 10_000)
        (usage_character_count_30d || 0) >= threshold
      end

      # Check if voice is available for free users
      #
      # @return [Boolean]
      def available_for_free?
        free_users_allowed != false
      end
    end
  end
end
