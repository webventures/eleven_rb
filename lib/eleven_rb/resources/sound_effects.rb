# frozen_string_literal: true

module ElevenRb
  module Resources
    # Sound effects generation resource
    #
    # @example Generate a sound effect
    #   audio = client.sound_effects.generate("thunder rumbling in the distance")
    #   audio.save_to_file("thunder.mp3")
    #
    # @example With options
    #   audio = client.sound_effects.generate(
    #     "footsteps on gravel",
    #     duration_seconds: 3.0,
    #     prompt_influence: 0.5
    #   )
    class SoundEffects < Base
      DEFAULT_MODEL = 'eleven_text_to_sound_v2'

      # Generate a sound effect from a text description
      #
      # @param text [String] description of the sound effect to generate
      # @param model_id [String] the model to use (default: eleven_text_to_sound_v2)
      # @param duration_seconds [Float, nil] desired duration in seconds (optional, API decides if omitted)
      # @param prompt_influence [Float, nil] how closely to follow the prompt (0.0-1.0)
      # @param loop [Boolean, nil] whether to generate a loopable sound effect
      # @param output_format [String] audio output format
      # @return [Objects::Audio]
      def generate(text, model_id: DEFAULT_MODEL, duration_seconds: nil, prompt_influence: nil, loop: nil,
                   output_format: 'mp3_44100_128')
        validate_presence!(text, 'text')

        body = {
          text: text,
          model_id: model_id
        }
        body[:duration_seconds] = duration_seconds unless duration_seconds.nil?
        body[:prompt_influence] = prompt_influence unless prompt_influence.nil?
        body[:loop] = loop unless loop.nil?

        path = "/sound-generation?output_format=#{output_format}"
        response = post_binary(path, body)

        audio = Objects::Audio.new(
          data: response,
          format: output_format,
          voice_id: nil,
          text: text,
          model_id: model_id
        )

        cost_info = Objects::CostInfo.new(text: text, voice_id: 'sound_effect', model_id: model_id)
        http_client.config.trigger(
          :on_audio_generated,
          audio: audio,
          voice_id: nil,
          text: text,
          cost_info: cost_info.to_h
        )

        audio
      end
    end
  end
end
