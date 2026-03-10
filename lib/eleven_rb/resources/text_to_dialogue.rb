# frozen_string_literal: true

module ElevenRb
  module Resources
    # Text-to-dialogue resource for multi-speaker audio generation
    #
    # @example Generate dialogue
    #   audio = client.text_to_dialogue.generate([
    #     { text: "[excited] Welcome!", voice_id: "voice_abc" },
    #     { text: "[laughs] Thanks!", voice_id: "voice_xyz" }
    #   ])
    #   audio.save_to_file("dialogue.mp3")
    class TextToDialogue < Base
      DEFAULT_MODEL = 'eleven_v3'
      MAX_VOICES_PER_REQUEST = 10
      MAX_TEXT_LENGTH = 5000

      # Generate dialogue audio from multiple speaker inputs
      #
      # @param inputs [Array<Hash>] Array of { text:, voice_id: } hashes
      # @param model_id [String] Model to use (only eleven_v3 supported)
      # @param language_code [String, nil] ISO 639-1 language code
      # @param settings [Hash, nil] Generation settings (stability: 0.0-1.0)
      # @param seed [Integer, nil] Seed for reproducibility
      # @param output_format [String] Audio output format
      # @param apply_text_normalization [String] "auto", "on", or "off"
      # @return [Objects::Audio]
      def generate(
        inputs,
        model_id: DEFAULT_MODEL,
        language_code: nil,
        settings: nil,
        seed: nil,
        output_format: 'mp3_44100_128',
        apply_text_normalization: 'auto'
      )
        validate_inputs!(inputs)

        body = build_request_body(inputs, model_id, language_code, settings, seed,
                                  apply_text_normalization)

        response = post_binary(
          "/text-to-dialogue?output_format=#{output_format}",
          body
        )

        build_audio_response(response, inputs, output_format, model_id)
      end

      private

      def build_request_body(inputs, model_id, language_code, settings, seed,
                             apply_text_normalization)
        body = {
          inputs: inputs.map { |i| { text: i[:text], voice_id: i[:voice_id] } },
          model_id: model_id,
          apply_text_normalization: apply_text_normalization
        }

        body[:language_code] = language_code if language_code
        body[:settings] = settings if settings
        body[:seed] = seed if seed
        body
      end

      def build_audio_response(response, inputs, output_format, model_id)
        total_text = inputs.map { |i| i[:text] }.join("\n")
        total_chars = inputs.sum { |i| i[:text].length }
        primary_voice = inputs.first[:voice_id]

        audio = Objects::Audio.new(
          data: response, format: output_format,
          voice_id: primary_voice, text: total_text, model_id: model_id
        )

        cost_info = Objects::CostInfo.new(
          character_count: total_chars, voice_id: primary_voice, model_id: model_id
        )

        http_client.config.trigger(
          :on_audio_generated,
          audio: audio, voice_id: primary_voice,
          text: total_text, cost_info: cost_info.to_h
        )

        audio
      end

      def validate_inputs!(inputs)
        raise Errors::ValidationError, 'inputs must be a non-empty array' unless inputs.is_a?(Array) && !inputs.empty?

        inputs.each_with_index do |input, i|
          validate_presence!(input[:text], "inputs[#{i}].text")
          validate_presence!(input[:voice_id], "inputs[#{i}].voice_id")
        end

        unique_voices = inputs.map { |i| i[:voice_id] }.uniq
        if unique_voices.length > MAX_VOICES_PER_REQUEST
          raise Errors::ValidationError,
                "Maximum #{MAX_VOICES_PER_REQUEST} unique voices per request " \
                "(got #{unique_voices.length})"
        end

        total_chars = inputs.sum { |i| i[:text].length }
        return unless total_chars > MAX_TEXT_LENGTH

        raise Errors::ValidationError,
              "Total text length #{total_chars} exceeds maximum " \
              "#{MAX_TEXT_LENGTH} characters"
      end
    end
  end
end
