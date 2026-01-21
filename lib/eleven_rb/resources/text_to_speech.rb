# frozen_string_literal: true

module ElevenRb
  module Resources
    # Text-to-speech resource
    #
    # @example Generate audio
    #   audio = client.tts.generate("Hello world", voice_id: "voice_id")
    #   audio.save_to_file("output.mp3")
    #
    # @example Stream audio
    #   client.tts.stream("Hello world", voice_id: "voice_id") do |chunk|
    #     io.write(chunk)
    #   end
    class TextToSpeech < Base
      DEFAULT_MODEL = 'eleven_multilingual_v2'
      MAX_TEXT_LENGTH = 5000

      OUTPUT_FORMATS = %w[
        mp3_44100_128
        mp3_44100_192
        pcm_16000
        pcm_22050
        pcm_24000
        pcm_44100
        ulaw_8000
      ].freeze

      # Generate audio from text
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use (default: eleven_multilingual_v2)
      # @param voice_settings [Hash] voice settings overrides
      # @param output_format [String] audio output format
      # @return [Objects::Audio]
      def generate(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {}, output_format: 'mp3_44100_128')
        validate_text!(text)
        validate_presence!(voice_id, 'voice_id')

        settings = Objects::VoiceSettings::DEFAULTS.merge(voice_settings)

        body = {
          text: text,
          model_id: model_id,
          voice_settings: settings
        }

        path = "/text-to-speech/#{voice_id}?output_format=#{output_format}"
        response = post_binary(path, body)

        audio = Objects::Audio.new(
          data: response,
          format: output_format,
          voice_id: voice_id,
          text: text,
          model_id: model_id
        )

        # Trigger cost tracking callback
        cost_info = Objects::CostInfo.new(text: text, voice_id: voice_id, model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: audio,
          voice_id: voice_id,
          text: text,
          cost_info: cost_info.to_h
        )

        audio
      end

      # Stream audio from text
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use
      # @param voice_settings [Hash] voice settings overrides
      # @param output_format [String] audio output format
      # @yield [String] each chunk of audio data
      # @return [void]
      def stream(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {}, output_format: 'mp3_44100_128', &block)
        validate_text!(text)
        validate_presence!(voice_id, 'voice_id')
        raise ArgumentError, 'Block required for streaming' unless block_given?

        settings = Objects::VoiceSettings::DEFAULTS.merge(voice_settings)

        body = {
          text: text,
          model_id: model_id,
          voice_settings: settings
        }

        path = "/text-to-speech/#{voice_id}/stream?output_format=#{output_format}"
        post_stream(path, body, &block)

        # Trigger cost tracking callback after streaming completes
        cost_info = Objects::CostInfo.new(text: text, voice_id: voice_id, model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: nil, # No audio object for streaming
          voice_id: voice_id,
          text: text,
          cost_info: cost_info.to_h
        )
      end

      # Generate audio with timestamps
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use
      # @param voice_settings [Hash] voice settings overrides
      # @param output_format [String] audio output format
      # @return [Hash] contains :audio and :alignment data
      def generate_with_timestamps(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {},
                                   output_format: 'mp3_44100_128')
        validate_text!(text)
        validate_presence!(voice_id, 'voice_id')

        settings = Objects::VoiceSettings::DEFAULTS.merge(voice_settings)

        body = {
          text: text,
          model_id: model_id,
          voice_settings: settings
        }

        path = "/text-to-speech/#{voice_id}/with-timestamps?output_format=#{output_format}"
        response = post(path, body)

        # Decode base64 audio
        audio_data = Base64.decode64(response['audio_base64']) if response['audio_base64']

        audio = if audio_data
                  Objects::Audio.new(
                    data: audio_data,
                    format: output_format,
                    voice_id: voice_id,
                    text: text,
                    model_id: model_id
                  )
                end

        {
          audio: audio,
          alignment: response['alignment']
        }
      end

      private

      def validate_text!(text)
        validate_presence!(text, 'text')

        return unless text.length > MAX_TEXT_LENGTH

        raise Errors::ValidationError,
              "text exceeds maximum length of #{MAX_TEXT_LENGTH} characters (got #{text.length})"
      end
    end
  end
end
