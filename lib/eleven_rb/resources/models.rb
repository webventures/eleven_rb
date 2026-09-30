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
    #
    # @example Find one model
    #   client.models.find('eleven_v4')
    class Models < Base
      # List all available models
      #
      # @return [Array<Objects::Model>]
      def list
        # Call the HTTP client directly: #get below is the model lookup (kept for
        # compatibility) and shadows Base#get, which made this method recurse.
        response = http_client.get('/models')
        response.map { |m| Objects::Model.from_response(m) }
      end

      # Find a specific model by ID
      #
      # @param model_id [String] the model ID
      # @return [Objects::Model, nil]
      def find(model_id)
        list.find { |m| m.model_id == model_id }
      end

      # Alias of {#find}, kept for backwards compatibility
      #
      # @param model_id [String] the model ID
      # @return [Objects::Model, nil]
      def get(model_id)
        find(model_id)
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
        default_from(list)
      end

      # Get the latest/most capable model available to the account:
      # eleven_v4, else eleven_v3, else {#default} (one /models request)
      #
      # @return [Objects::Model, nil]
      def latest
        models = list
        %w[eleven_v4 eleven_v3].each do |model_id|
          model = models.find { |m| m.model_id == model_id }
          return model if model
        end
        default_from(models)
      end

      # Get model IDs as array
      #
      # @return [Array<String>]
      def ids
        list.map(&:model_id)
      end

      private

      # eleven_multilingual_v2, else the first TTS-capable model, from an already-fetched list
      def default_from(models)
        models.find { |m| m.model_id == 'eleven_multilingual_v2' } || models.find(&:can_do_text_to_speech)
      end
    end
  end
end
