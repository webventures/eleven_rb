# frozen_string_literal: true

module ElevenRb
  module Resources
    # Voice management resource
    #
    # @example List all voices
    #   client.voices.list
    #
    # @example Get a specific voice
    #   client.voices.get("voice_id")
    #
    # @example Delete a voice
    #   client.voices.delete("voice_id")
    class Voices < Base
      # List all voices in your account
      #
      # @return [Collections::VoiceCollection]
      def list
        response = get("/voices")
        Collections::VoiceCollection.from_response(response)
      end

      # Get details for a specific voice
      #
      # @param voice_id [String] the voice ID
      # @return [Objects::Voice]
      def find(voice_id)
        validate_presence!(voice_id, "voice_id")
        response = get("/voices/#{voice_id}")
        Objects::Voice.from_response(response)
      end

      # Delete a voice from your account
      #
      # @param voice_id [String] the voice ID
      # @return [Boolean] true if successful
      def destroy(voice_id)
        validate_presence!(voice_id, "voice_id")
        response = delete("/voices/#{voice_id}")

        # Trigger callback
        http_client.config.trigger(:on_voice_deleted, voice_id: voice_id)

        response["status"] == "ok"
      end

      # Create a new voice from audio samples (Instant Voice Cloning)
      #
      # @param name [String] voice name
      # @param samples [Array<File>] audio sample files
      # @param description [String, nil] voice description
      # @param labels [Hash] voice labels (e.g., { "accent" => "British" })
      # @return [Objects::Voice]
      def create(name:, samples:, description: nil, labels: {})
        validate_presence!(name, "name")
        validate_samples!(samples)

        params = {
          name: name,
          files: samples
        }
        params[:description] = description if description
        params[:labels] = labels.to_json unless labels.empty?

        response = post_multipart("/voices/add", params)

        # Trigger callback
        http_client.config.trigger(:on_voice_added, voice_id: response["voice_id"], name: name)

        Objects::Voice.from_response(response)
      end

      # Update an existing voice
      #
      # @param voice_id [String] the voice ID
      # @param name [String, nil] new name
      # @param description [String, nil] new description
      # @param samples [Array<File>, nil] additional audio samples
      # @param labels [Hash, nil] new labels
      # @return [Objects::Voice]
      def update(voice_id, name: nil, description: nil, samples: nil, labels: nil)
        validate_presence!(voice_id, "voice_id")

        params = {}
        params[:name] = name if name
        params[:description] = description if description
        params[:labels] = labels.to_json if labels
        params[:files] = samples if samples

        if samples
          response = post_multipart("/voices/#{voice_id}/edit", params)
        else
          response = post("/voices/#{voice_id}/edit", params)
        end

        Objects::Voice.from_response(response)
      end

      # Get default voice settings
      #
      # @return [Objects::VoiceSettings]
      def default_settings
        response = get("/voices/settings/default")
        Objects::VoiceSettings.from_response(response)
      end

      # Get settings for a specific voice
      #
      # @param voice_id [String] the voice ID
      # @return [Objects::VoiceSettings]
      def settings(voice_id)
        validate_presence!(voice_id, "voice_id")
        response = get("/voices/#{voice_id}/settings")
        Objects::VoiceSettings.from_response(response)
      end

      # Update settings for a voice
      #
      # @param voice_id [String] the voice ID
      # @param settings [Hash] the settings to update
      # @return [Boolean]
      def update_settings(voice_id, settings)
        validate_presence!(voice_id, "voice_id")
        response = post("/voices/#{voice_id}/settings/edit", settings)
        response["status"] == "ok"
      end

      private

      def validate_samples!(samples)
        unless samples.is_a?(Array) && samples.any?
          raise Errors::ValidationError, "samples must be an array of files"
        end
      end
    end
  end
end
