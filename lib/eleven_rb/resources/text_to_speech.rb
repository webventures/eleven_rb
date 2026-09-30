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
    #
    # @example Eleven v4 with continuity and a fixed seed
    #   audio = client.tts.generate(
    #     "[sighs] Right. Let's try that again.",
    #     voice_id: "voice_id",
    #     model_id: "eleven_v4",
    #     seed: 42,
    #     previous_text: "That did not go to plan."
    #   )
    #   audio.request_id # => "abc123" (from the request-id response header)
    class TextToSpeech < Base
      DEFAULT_MODEL = 'eleven_multilingual_v2'

      # Kept for compatibility. The per-request cap now comes from
      # ModelCapabilities.max_text_length(model_id) (5,000 for eleven_v3).
      MAX_TEXT_LENGTH = 5000

      # Output formats the API accepts (documentation only; not validated)
      OUTPUT_FORMATS = %w[
        mp3_22050_32
        mp3_24000_48
        mp3_44100_32
        mp3_44100_64
        mp3_44100_96
        mp3_44100_128
        mp3_44100_192
        opus_48000_32
        opus_48000_64
        opus_48000_96
        opus_48000_128
        opus_48000_192
        pcm_8000
        pcm_16000
        pcm_22050
        pcm_24000
        pcm_32000
        pcm_44100
        pcm_48000
        wav_8000
        wav_16000
        wav_22050
        wav_24000
        wav_32000
        wav_44100
        wav_48000
        ulaw_8000
        alaw_8000
      ].freeze

      # Optional request-body keys, in the order they are written to the body.
      # Each is omitted from the body when nil.
      OPTIONAL_BODY_KEYS = %i[
        language_code
        apply_text_normalization
        seed
        previous_text
        next_text
        previous_request_ids
        next_request_ids
        pronunciation_dictionary_locators
        use_pvc_as_ivc
      ].freeze

      # Generate audio from text
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use (default: eleven_multilingual_v2)
      # @param voice_settings [Hash] voice settings overrides (keys the model ignores are dropped)
      # @param output_format [String] audio output format
      # @param language_code [String, nil] ISO 639-1 language code to enforce
      # @param apply_text_normalization [String, nil] "auto", "on" or "off"
      # @param seed [Integer, nil] seed for reproducible generation
      # @param previous_text [String, nil] text that comes before this request (continuity)
      # @param next_text [String, nil] text that comes after this request (continuity)
      # @param previous_request_ids [Array<String>, nil] request IDs of preceding generations
      # @param next_request_ids [Array<String>, nil] request IDs of following generations
      # @param pronunciation_dictionary_locators [Array<Hash>, nil] `{ pronunciation_dictionary_id:, version_id: }`
      # @param use_pvc_as_ivc [Boolean, nil] use the IVC version of a professional voice
      # @return [Objects::Audio] with request_id, character_cost and dropped_settings
      def generate(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {}, output_format: 'mp3_44100_128',
                   language_code: nil, apply_text_normalization: nil, seed: nil, previous_text: nil,
                   next_text: nil, previous_request_ids: nil, next_request_ids: nil,
                   pronunciation_dictionary_locators: nil, use_pvc_as_ivc: nil)
        validate_text!(text, model_id)
        validate_presence!(voice_id, 'voice_id')
        body, dropped = build_body(text, model_id, voice_settings, optional_values(binding))

        path = "/text-to-speech/#{voice_id}?output_format=#{output_format}"
        response = post_binary_with_meta(path, body)
        headers = response[:headers]

        audio = Objects::Audio.new(
          data: response[:body],
          format: output_format,
          voice_id: voice_id,
          text: text,
          model_id: model_id,
          request_id: headers['request-id'],
          character_cost: integer_header(headers, 'character-cost'),
          dropped_settings: dropped
        )

        # Trigger cost tracking callback
        cost_info = Objects::CostInfo.new(text: text, voice_id: voice_id, model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: audio,
          voice_id: voice_id,
          text: text,
          cost_info: cost_info.to_h,
          request_id: audio.request_id
        )

        audio
      end

      # Stream audio from text
      #
      # Takes the same optional keywords as {#generate}.
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use
      # @param voice_settings [Hash] voice settings overrides
      # @param output_format [String] audio output format
      # @yield [String] each chunk of audio data
      # @return [void]
      def stream(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {}, output_format: 'mp3_44100_128',
                 language_code: nil, apply_text_normalization: nil, seed: nil, previous_text: nil,
                 next_text: nil, previous_request_ids: nil, next_request_ids: nil,
                 pronunciation_dictionary_locators: nil, use_pvc_as_ivc: nil, &block)
        validate_text!(text, model_id)
        validate_presence!(voice_id, 'voice_id')
        raise ArgumentError, 'Block required for streaming' unless block_given?

        body, = build_body(text, model_id, voice_settings, optional_values(binding))

        path = "/text-to-speech/#{voice_id}/stream?output_format=#{output_format}"
        post_stream(path, body, &block)

        # Trigger cost tracking callback after streaming completes
        cost_info = Objects::CostInfo.new(text: text, voice_id: voice_id, model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: nil, # No audio object for streaming
          voice_id: voice_id,
          text: text,
          cost_info: cost_info.to_h,
          request_id: nil
        )
      end

      # Generate audio with timestamps
      #
      # Takes the same optional keywords as {#generate}.
      #
      # @param text [String] the text to convert
      # @param voice_id [String] the voice ID to use
      # @param model_id [String] the model to use
      # @param voice_settings [Hash] voice settings overrides
      # @param output_format [String] audio output format
      # @return [Hash] `{ audio:, alignment:, normalized_alignment:, request_id:, character_cost: }`
      def generate_with_timestamps(text, voice_id:, model_id: DEFAULT_MODEL, voice_settings: {},
                                   output_format: 'mp3_44100_128', language_code: nil,
                                   apply_text_normalization: nil, seed: nil, previous_text: nil,
                                   next_text: nil, previous_request_ids: nil, next_request_ids: nil,
                                   pronunciation_dictionary_locators: nil, use_pvc_as_ivc: nil)
        validate_text!(text, model_id)
        validate_presence!(voice_id, 'voice_id')
        body, dropped = build_body(text, model_id, voice_settings, optional_values(binding))

        path = "/text-to-speech/#{voice_id}/with-timestamps?output_format=#{output_format}"
        result = post_with_meta(path, body)
        response = result[:body]
        request_id = result[:headers]['request-id']
        character_cost = integer_header(result[:headers], 'character-cost')

        # Decode base64 audio
        audio_data = Base64.decode64(response['audio_base64']) if response['audio_base64']

        audio = if audio_data
                  Objects::Audio.new(
                    data: audio_data,
                    format: output_format,
                    voice_id: voice_id,
                    text: text,
                    model_id: model_id,
                    request_id: request_id,
                    character_cost: character_cost,
                    dropped_settings: dropped
                  )
                end

        {
          audio: audio,
          alignment: response['alignment'],
          normalized_alignment: response['normalized_alignment'],
          request_id: request_id,
          character_cost: character_cost
        }
      end

      private

      # Shared request body for generate / stream / generate_with_timestamps
      #
      # @return [Array(Hash, Array<Symbol>)] the body and the dropped voice-setting keys
      def build_body(text, model_id, voice_settings, options)
        settings, dropped = resolve_voice_settings(model_id, voice_settings)

        body = { text: text, model_id: model_id, voice_settings: settings }
        OPTIONAL_BODY_KEYS.each do |key|
          body[key] = options[key] unless options[key].nil?
        end

        [body, dropped]
      end

      # The optional keyword values of the calling method, keyed by OPTIONAL_BODY_KEYS
      def optional_values(caller_binding)
        OPTIONAL_BODY_KEYS.to_h { |key| [key, caller_binding.local_variable_get(key)] }
      end

      def resolve_voice_settings(model_id, voice_settings)
        settings, dropped = Objects::VoiceSettings.for_model(model_id, voice_settings)
        return [settings, dropped] if dropped.empty?

        message = "voice settings #{dropped.map(&:to_s).join(', ')} are not supported by #{model_id} " \
                  "(supported: #{ModelCapabilities.supported_voice_settings(model_id).join(', ')})"
        raise Errors::ValidationError, message if http_client.config.strict_voice_settings

        http_client.config.logger&.warn("[ElevenRb] #{message}; dropped from the request")
        [settings, dropped]
      end

      def integer_header(headers, name)
        value = headers[name]
        return nil if value.nil? || value.to_s.strip.empty?

        Integer(value.to_s.strip, 10)
      rescue ArgumentError
        nil
      end

      def validate_text!(text, model_id = DEFAULT_MODEL)
        validate_presence!(text, 'text')

        max_length = ModelCapabilities.max_text_length(model_id)
        return unless text.length > max_length

        raise Errors::ValidationError,
              "text exceeds maximum length of #{max_length} characters for #{model_id} (got #{text.length})"
      end
    end
  end
end
