# frozen_string_literal: true

module ElevenRb
  module Resources
    # Speech-to-speech voice conversion resource
    #
    # Converts audio from one voice to another while preserving timing,
    # cadence, and emotion. Uses ElevenLabs STS API with multipart upload.
    #
    # @example Convert a file
    #   audio = client.sts.convert("input.mp3", voice_id: "abc123")
    #   audio.save_to_file("output.mp3")
    #
    # @example Convert an IO object
    #   io = File.open("input.mp3", "rb")
    #   audio = client.sts.convert(io, voice_id: "abc123")
    class SpeechToSpeech < Base
      DEFAULT_MODEL = 'eleven_english_sts_v2'
      MAX_INPUT_BYTES = 50 * 1024 * 1024 # 50 MB

      # Convert speech from one voice to another
      #
      # @param audio_input [String, IO, Tempfile] file path or IO object of source audio
      # @param voice_id [String] target voice ID to convert into
      # @param model_id [String] STS model (default: eleven_english_sts_v2)
      # @param voice_settings [Hash, nil] override voice settings (stability, similarity_boost)
      # @param remove_background_noise [Boolean] isolate speech before conversion
      # @param output_format [String] audio output format
      # @param seed [Integer, nil] for reproducible results
      # @return [Objects::Audio]
      def convert(audio_input, voice_id:, model_id: DEFAULT_MODEL,
                  voice_settings: nil, remove_background_noise: false,
                  output_format: 'mp3_44100_128', seed: nil)
        validate_presence!(voice_id, 'voice_id')

        file = prepare_upload(audio_input)

        params = {
          audio: file,
          model_id: model_id
        }
        params[:voice_settings] = voice_settings.to_json if voice_settings
        params[:remove_background_noise] = remove_background_noise.to_s
        params[:seed] = seed.to_s if seed

        path = "/speech-to-speech/#{voice_id}?output_format=#{output_format}"
        response = post_multipart(path, params, response_type: :binary)

        audio = Objects::Audio.new(
          data: response,
          format: output_format,
          voice_id: voice_id,
          text: '[speech-to-speech]',
          model_id: model_id
        )

        notify_audio_generated(audio, voice_id: voice_id, model_id: model_id)
        audio
      ensure
        file&.close if file.respond_to?(:close) && audio_input.is_a?(String)
      end

      private

      def notify_audio_generated(audio, voice_id:, model_id:)
        cost_info = Objects::CostInfo.new(text: '[sts]', voice_id: voice_id, model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: audio,
          voice_id: voice_id,
          text: '[speech-to-speech]',
          cost_info: cost_info.to_h
        )
      end

      # Prepare the audio input for multipart upload
      #
      # @param input [String, IO, StringIO, Tempfile] file path or IO object
      # @return [IO] file handle ready for upload
      def prepare_upload(input)
        case input
        when String
          raise Errors::ValidationError, "File not found: #{input}" unless File.exist?(input)

          File.open(input, 'rb')
        when IO, StringIO, Tempfile
          input
        else
          raise ArgumentError, "Expected file path or IO object, got #{input.class}"
        end
      end
    end
  end
end
