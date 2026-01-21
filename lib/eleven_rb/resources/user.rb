# frozen_string_literal: true

module ElevenRb
  module Resources
    # User/account resource
    #
    # @example Get subscription info
    #   sub = client.user.subscription
    #   puts sub.characters_remaining
    #
    # @example Get user info
    #   info = client.user.info
    class User < Base
      # Get subscription information
      #
      # @return [Objects::Subscription]
      def subscription
        response = get("/user/subscription")
        Objects::Subscription.from_response(response)
      end

      # Get user account information
      #
      # @return [Objects::UserInfo]
      def info
        response = get("/user")
        Objects::UserInfo.from_response(response)
      end

      # Get subscription with current voice count
      # This makes an additional API call to count voices
      #
      # @return [Objects::Subscription]
      def subscription_with_voice_count(voices_count)
        sub = subscription
        sub.voice_slots_used = voices_count
        sub
      end

      # Check if user can add more voices
      #
      # @param current_voice_count [Integer]
      # @return [Boolean]
      def can_add_voice?(current_voice_count)
        sub = subscription
        return true unless sub.voice_limit

        current_voice_count < sub.voice_limit
      end

      # Get character usage summary
      #
      # @return [Hash]
      def character_usage
        sub = subscription
        {
          used: sub.character_count,
          limit: sub.character_limit,
          remaining: sub.characters_remaining,
          percentage: sub.characters_used_percentage,
          resets_at: sub.next_reset_at
        }
      end
    end
  end
end
