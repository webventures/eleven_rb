# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::SoundEffects do
  let(:client) { test_client }
  let(:sfx) { client.sound_effects }

  describe '#generate' do
    it 'returns an audio object' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=mp3_44100_128',
        response_body: 'fake sfx data'
      )

      audio = sfx.generate('thunder rumbling')

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('fake sfx data')
      expect(audio.voice_id).to be_nil
      expect(audio.text).to eq('thunder rumbling')
    end

    it 'raises error for blank text' do
      expect { sfx.generate('') }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'raises error for nil text' do
      expect { sfx.generate(nil) }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'includes optional params in request body' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      sfx.generate('wind', duration_seconds: 5.0, prompt_influence: 0.3, loop: true)

      expect(WebMock).to(have_requested(:post, %r{/v1/sound-generation})
        .with do |req|
          body = JSON.parse(req.body)
          body.key?('duration_seconds') &&
            body.key?('prompt_influence') &&
            body['loop'] == true
        end)
    end

    it 'omits optional params when not provided' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      sfx.generate('wind')

      expect(WebMock).to(have_requested(:post, %r{/v1/sound-generation})
        .with do |req|
          body = JSON.parse(req.body)
          !body.key?('duration_seconds') &&
            !body.key?('prompt_influence') &&
            !body.key?('loop')
        end)
    end

    it 'triggers on_audio_generated callback' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) { received_cost_info = cost_info }
      )

      client_with_callback.sound_effects.generate('explosion')

      expect(received_cost_info).to include(:character_count, :estimated_cost)
    end

    it 'accepts custom output_format' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=pcm_44100',
        response_body: 'pcm audio'
      )

      audio = sfx.generate('rain', output_format: 'pcm_44100')

      expect(audio.format).to eq('pcm_44100')
    end

    it 'accepts custom model_id' do
      stub_elevenlabs_binary_request(
        :post,
        '/sound-generation?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      sfx.generate('rain', model_id: 'custom_model')

      expect(WebMock).to(have_requested(:post, %r{/v1/sound-generation})
        .with { |req| JSON.parse(req.body)['model_id'] == 'custom_model' })
    end
  end
end
