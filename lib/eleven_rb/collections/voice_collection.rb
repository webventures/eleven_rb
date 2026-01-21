# frozen_string_literal: true

module ElevenRb
  module Collections
    # Collection of Voice objects
    class VoiceCollection < Base
      # Find voice by ID
      #
      # @param voice_id [String]
      # @return [Objects::Voice, nil]
      def find_by_id(voice_id)
        items.find { |v| v.voice_id == voice_id }
      end

      # Find voice by name (case-insensitive)
      #
      # @param name [String]
      # @return [Objects::Voice, nil]
      def find_by_name(name)
        items.find { |v| v.name&.downcase == name.downcase }
      end

      # Filter voices by gender
      #
      # @param gender [String]
      # @return [Array<Objects::Voice>]
      def by_gender(gender)
        items.select { |v| v.gender&.downcase == gender.downcase }
      end

      # Filter voices by language
      #
      # @param language [String]
      # @return [Array<Objects::Voice>]
      def by_language(language)
        items.select { |v| v.language&.downcase == language.downcase }
      end

      # Filter voices by accent
      #
      # @param accent [String]
      # @return [Array<Objects::Voice>]
      def by_accent(accent)
        items.select { |v| v.accent&.downcase&.include?(accent.downcase) }
      end

      # Filter voices by category
      #
      # @param category [String]
      # @return [Array<Objects::Voice>]
      def by_category(category)
        items.select { |v| v.category&.downcase == category.downcase }
      end

      # Get all voice IDs
      #
      # @return [Array<String>]
      def voice_ids
        items.map(&:voice_id)
      end

      # Check if voice ID exists in collection
      #
      # @param voice_id [String]
      # @return [Boolean]
      def include_voice?(voice_id)
        voice_ids.include?(voice_id)
      end

      private

      def parse_items(response)
        voices = response["voices"] || response || []
        voices.map { |v| Objects::Voice.from_response(v) }
      end
    end
  end
end
