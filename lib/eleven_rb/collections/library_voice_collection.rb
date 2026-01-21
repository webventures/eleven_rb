# frozen_string_literal: true

module ElevenRb
  module Collections
    # Collection of LibraryVoice objects from the shared voice library
    class LibraryVoiceCollection < Base
      # Check if there are more results
      #
      # @return [Boolean]
      def has_more?
        raw_response["has_more"] == true
      end

      # Get the cursor for next page
      #
      # @return [String, nil]
      def next_cursor
        raw_response["last_sort_id"]
      end

      # Find voice by ID
      #
      # @param voice_id [String]
      # @return [Objects::LibraryVoice, nil]
      def find_by_id(voice_id)
        items.find { |v| v.voice_id == voice_id }
      end

      # Find voice by name (case-insensitive)
      #
      # @param name [String]
      # @return [Objects::LibraryVoice, nil]
      def find_by_name(name)
        items.find { |v| v.name&.downcase == name.downcase }
      end

      # Filter voices by gender
      #
      # @param gender [String]
      # @return [Array<Objects::LibraryVoice>]
      def by_gender(gender)
        items.select { |v| v.gender&.downcase == gender.downcase }
      end

      # Filter voices by language
      #
      # @param language [String]
      # @return [Array<Objects::LibraryVoice>]
      def by_language(language)
        items.select { |v| v.language&.downcase == language.downcase }
      end

      # Filter voices by accent
      #
      # @param accent [String]
      # @return [Array<Objects::LibraryVoice>]
      def by_accent(accent)
        items.select { |v| v.accent&.downcase&.include?(accent.downcase) }
      end

      # Get popular voices (high usage)
      #
      # @param threshold [Integer]
      # @return [Array<Objects::LibraryVoice>]
      def popular(threshold: 10_000)
        items.select { |v| v.popular?(threshold: threshold) }
      end

      # Get voices available for free users
      #
      # @return [Array<Objects::LibraryVoice>]
      def free_tier
        items.select(&:available_for_free?)
      end

      # Get verified voices only
      #
      # @return [Array<Objects::LibraryVoice>]
      def verified
        items.select(&:verified)
      end

      private

      def parse_items(response)
        voices = response["voices"] || []
        voices.map { |v| Objects::LibraryVoice.from_response(v) }
      end
    end
  end
end
