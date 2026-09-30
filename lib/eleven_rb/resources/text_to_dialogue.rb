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
    #
    # @example Dialogue with timestamps and per-speaker segments
    #   result = client.dialogue.generate_with_timestamps(inputs, seed: 7)
    #   result[:voice_segments] # => [{ "voice_id" => ..., "start_time_seconds" => ... }, ...]
    class TextToDialogue < Base
      DEFAULT_MODEL = 'eleven_v4'
      MAX_VOICES_PER_REQUEST = 10

      # Kept for compatibility. The hard cap now comes from
      # ModelCapabilities.max_text_length(model_id) (5,000 for eleven_v3).
      MAX_TEXT_LENGTH = 5000

      # Above this many characters the API recommends splitting the dialogue;
      # the gem logs a warning but still sends the request.
      RECOMMENDED_MAX_TEXT_LENGTH = 2_000

      # Optional request-body keys, in the order they are written to the body.
      # Each is omitted from the body when nil.
      OPTIONAL_BODY_KEYS = %i[
        language_code
        settings
        seed
        use_pvc_as_ivc
        previous_text
        future_text
        previous_request_ids
        next_request_ids
        pronunciation_dictionary_locators
      ].freeze

      # Generate dialogue audio from multiple speaker inputs
      #
      # @param inputs [Array<Hash>] Array of { text:, voice_id: } hashes
      # @param model_id [String] Model to use (default: eleven_v4)
      # @param language_code [String, nil] ISO 639-1 language code
      # @param settings [Hash, nil] Generation settings, sent unchanged (e.g. stability, similarity)
      # @param seed [Integer, nil] Seed for reproducibility
      # @param output_format [String] Audio output format
      # @param apply_text_normalization [String] "auto", "on", or "off"
      # @param use_pvc_as_ivc [Boolean, nil] use the IVC version of professional voices
      # @param previous_text [String, nil] text that comes before this dialogue (continuity)
      # @param future_text [String, nil] text that comes after this dialogue (continuity)
      # @param previous_request_ids [Array<String>, nil] request IDs of preceding generations
      # @param next_request_ids [Array<String>, nil] request IDs of following generations
      # @param pronunciation_dictionary_locators [Array<Hash>, nil] pronunciation dictionaries to apply
      # @return [Objects::Audio]
      def generate(
        inputs,
        model_id: DEFAULT_MODEL,
        language_code: nil,
        settings: nil,
        seed: nil,
        output_format: 'mp3_44100_128',
        apply_text_normalization: 'auto',
        use_pvc_as_ivc: nil,
        previous_text: nil,
        future_text: nil,
        previous_request_ids: nil,
        next_request_ids: nil,
        pronunciation_dictionary_locators: nil
      )
        validate_inputs!(inputs, model_id)

        body = build_request_body(inputs, model_id, apply_text_normalization, optional_values(binding))
        response = post_binary_with_meta("/text-to-dialogue?output_format=#{output_format}", body)

        build_audio_response(response[:body], inputs, output_format, model_id,
                             request_id: response[:headers]['request-id'])
      end

      # Generate dialogue audio with character timestamps and per-voice segments
      #
      # Takes the same keywords as {#generate}.
      #
      # @param inputs [Array<Hash>] Array of { text:, voice_id: } hashes
      # @return [Hash] `{ audio:, alignment:, normalized_alignment:, voice_segments:, request_id: }`
      def generate_with_timestamps(
        inputs,
        model_id: DEFAULT_MODEL,
        language_code: nil,
        settings: nil,
        seed: nil,
        output_format: 'mp3_44100_128',
        apply_text_normalization: 'auto',
        use_pvc_as_ivc: nil,
        previous_text: nil,
        future_text: nil,
        previous_request_ids: nil,
        next_request_ids: nil,
        pronunciation_dictionary_locators: nil
      )
        validate_inputs!(inputs, model_id)

        body = build_request_body(inputs, model_id, apply_text_normalization, optional_values(binding))
        result = post_with_meta("/text-to-dialogue/with-timestamps?output_format=#{output_format}", body)
        response = result[:body]
        request_id = result[:headers]['request-id']

        audio_data = Base64.decode64(response['audio_base64']) if response['audio_base64']
        audio = (build_audio_response(audio_data, inputs, output_format, model_id, request_id: request_id) if audio_data)

        {
          audio: audio,
          alignment: response['alignment'],
          normalized_alignment: response['normalized_alignment'],
          voice_segments: response['voice_segments'],
          request_id: request_id
        }
      end

      private

      # The optional keyword values of the calling method, keyed by OPTIONAL_BODY_KEYS
      def optional_values(caller_binding)
        OPTIONAL_BODY_KEYS.to_h { |key| [key, caller_binding.local_variable_get(key)] }
      end

      def build_request_body(inputs, model_id, apply_text_normalization, options)
        body = {
          inputs: inputs.map { |i| { text: i[:text], voice_id: i[:voice_id] } },
          model_id: model_id,
          apply_text_normalization: apply_text_normalization
        }

        OPTIONAL_BODY_KEYS.each do |key|
          body[key] = options[key] unless options[key].nil?
        end
        body
      end

      def build_audio_response(data, inputs, output_format, model_id, request_id: nil)
        total_text = inputs.map { |i| i[:text] }.join("\n")
        total_chars = inputs.sum { |i| i[:text].length }
        primary_voice = inputs.first[:voice_id]

        audio = Objects::Audio.new(
          data: data, format: output_format,
          voice_id: primary_voice, text: total_text, model_id: model_id,
          request_id: request_id
        )

        cost_info = Objects::CostInfo.new(
          character_count: total_chars, voice_id: primary_voice, model_id: model_id
        )

        http_client.config.trigger(
          :on_audio_generated,
          audio: audio, voice_id: primary_voice,
          text: total_text, cost_info: cost_info.to_h,
          request_id: request_id
        )

        audio
      end

      def validate_inputs!(inputs, model_id = DEFAULT_MODEL)
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

        validate_text_length!(inputs.sum { |i| i[:text].length }, model_id)
      end

      def validate_text_length!(total_chars, model_id)
        max_length = ModelCapabilities.max_text_length(model_id)
        if total_chars > max_length
          raise Errors::ValidationError,
                "Total text length #{total_chars} exceeds maximum " \
                "#{max_length} characters for #{model_id}"
        end

        return unless total_chars > RECOMMENDED_MAX_TEXT_LENGTH

        http_client.config.logger&.warn(
          "[ElevenRb] text-to-dialogue text is #{total_chars} characters; " \
          "#{RECOMMENDED_MAX_TEXT_LENGTH} or fewer per request is recommended"
        )
      end
    end
  end
end
