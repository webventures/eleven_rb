# frozen_string_literal: true

module ElevenRb
  module Resources
    # Music generation resource
    #
    # @example Generate music from a prompt
    #   audio = client.music.generate("upbeat jazz piano solo")
    #   audio.save_to_file("jazz.mp3")
    #
    # @example Generate music from a composition plan
    #   plan = client.music.create_plan("epic orchestral battle theme", music_length_ms: 30_000)
    #   audio = client.music.generate(composition_plan: plan)
    #   audio.save_to_file("battle.mp3")
    #
    # @example Stream music
    #   File.open("song.mp3", "wb") do |file|
    #     client.music.stream("lo-fi hip hop beats") { |chunk| file.write(chunk) }
    #   end
    class Music < Base
      DEFAULT_MODEL = 'music_v1'

      # Generate music from a text prompt or composition plan
      #
      # @param prompt [String, nil] text description of the music to generate (mutually exclusive with composition_plan)
      # @param composition_plan [Hash, nil] structured composition plan (mutually exclusive with prompt)
      # @param music_length_ms [Integer, nil] duration in milliseconds (3000-600000, only with prompt)
      # @param model_id [String] the model to use (default: music_v1)
      # @param force_instrumental [Boolean, nil] whether to force instrumental output (only with prompt)
      # @param respect_sections_durations [Boolean, nil] whether to respect section durations (only with compose)
      # @param output_format [String] audio output format
      # @return [Objects::Audio]
      def generate(prompt = nil, composition_plan: nil, music_length_ms: nil,
                   model_id: DEFAULT_MODEL, force_instrumental: nil,
                   respect_sections_durations: nil, output_format: 'mp3_44100_128')
        validate_prompt_or_plan!(prompt, composition_plan)

        body = build_body(
          prompt: prompt,
          composition_plan: composition_plan,
          music_length_ms: music_length_ms,
          model_id: model_id,
          force_instrumental: force_instrumental,
          respect_sections_durations: respect_sections_durations
        )

        path = "/music?output_format=#{output_format}"
        response = post_binary(path, body)

        audio = Objects::Audio.new(
          data: response,
          format: output_format,
          voice_id: nil,
          text: prompt,
          model_id: model_id
        )

        cost_info = Objects::CostInfo.new(text: prompt || '', voice_id: 'music', model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: audio,
          voice_id: nil,
          text: prompt,
          cost_info: cost_info.to_h
        )

        audio
      end

      # Stream music from a text prompt or composition plan
      #
      # @param prompt [String, nil] text description of the music to generate
      # @param composition_plan [Hash, nil] structured composition plan
      # @param music_length_ms [Integer, nil] duration in milliseconds (3000-600000, only with prompt)
      # @param model_id [String] the model to use
      # @param force_instrumental [Boolean, nil] whether to force instrumental output (only with prompt)
      # @param output_format [String] audio output format
      # @yield [String] each chunk of audio data
      # @return [void]
      def stream(prompt = nil, composition_plan: nil, music_length_ms: nil,
                 model_id: DEFAULT_MODEL, force_instrumental: nil,
                 output_format: 'mp3_44100_128', &block)
        validate_prompt_or_plan!(prompt, composition_plan)
        raise ArgumentError, 'Block required for streaming' unless block_given?

        body = build_body(
          prompt: prompt,
          composition_plan: composition_plan,
          music_length_ms: music_length_ms,
          model_id: model_id,
          force_instrumental: force_instrumental
        )

        path = "/music/stream?output_format=#{output_format}"
        post_stream(path, body, &block)

        cost_info = Objects::CostInfo.new(text: prompt || '', voice_id: 'music', model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: nil,
          voice_id: nil,
          text: prompt,
          cost_info: cost_info.to_h
        )
      end

      # Create a composition plan from a text prompt (free, no credits used)
      #
      # @param prompt [String] text description of the music
      # @param music_length_ms [Integer, nil] desired duration in milliseconds
      # @param model_id [String] the model to use
      # @return [Hash] structured composition plan
      def create_plan(prompt, music_length_ms: nil, model_id: DEFAULT_MODEL)
        validate_presence!(prompt, 'prompt')

        body = {
          prompt: prompt,
          model_id: model_id
        }
        body[:music_length_ms] = music_length_ms unless music_length_ms.nil?

        post('/music/plan', body)
      end

      private

      def validate_prompt_or_plan!(prompt, composition_plan)
        raise Errors::ValidationError, 'Either prompt or composition_plan must be provided' if prompt.nil? && composition_plan.nil?

        return unless prompt && composition_plan

        raise Errors::ValidationError, 'prompt and composition_plan are mutually exclusive'
      end

      def build_body(prompt:, composition_plan:, music_length_ms:, model_id:,
                     force_instrumental: nil, respect_sections_durations: nil)
        body = { model_id: model_id }

        if prompt
          body[:prompt] = prompt
          body[:music_length_ms] = music_length_ms unless music_length_ms.nil?
          body[:force_instrumental] = force_instrumental unless force_instrumental.nil?
        else
          body[:composition_plan] = composition_plan
        end

        body[:respect_sections_durations] = respect_sections_durations unless respect_sections_durations.nil?

        body
      end
    end
  end
end
