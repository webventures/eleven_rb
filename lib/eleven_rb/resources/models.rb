# frozen_string_literal: true

module ElevenRb
  module Resources
    # Models resource
    #
    # @example List all models
    #   models = client.models.list
    #
    # @example Find multilingual models
    #   client.models.multilingual
    class Models < Base
      # List all available models
      #
      # @return [Array<Objects::Model>]
      def list
        response = get("/models")
        response.map { |m| Objects::Model.from_response(m) }
      end

      # Get a specific model by ID
      #
      # @param model_id [String] the model ID
      # @return [Objects::Model, nil]
      def get(model_id)
        list.find { |m| m.model_id == model_id }
      end

      # Get all multilingual models
      #
      # @return [Array<Objects::Model>]
      def multilingual
        list.select(&:multilingual?)
      end

      # Get all turbo/fast models
      #
      # @return [Array<Objects::Model>]
      def turbo
        list.select(&:turbo?)
      end

      # Get models that support TTS
      #
      # @return [Array<Objects::Model>]
      def tts_capable
        list.select(&:can_do_text_to_speech)
      end

      # Get the default/recommended model for TTS
      #
      # @return [Objects::Model, nil]
      def default
        get("eleven_multilingual_v2") || tts_capable.first
      end

      # Get model IDs as array
      #
      # @return [Array<String>]
      def ids
        list.map(&:model_id)
      end
    end
  end
end
