# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::Music do
  let(:client) { test_client }
  let(:music) { client.music }

  describe '#generate' do
    it 'returns an audio object from a prompt' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'fake music data'
      )

      audio = music.generate('upbeat jazz piano')

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('fake music data')
      expect(audio.voice_id).to be_nil
      expect(audio.text).to eq('upbeat jazz piano')
    end

    it 'returns an audio object from a composition plan' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'planned music data'
      )

      plan = { 'global_style' => 'jazz', 'sections' => [] }
      audio = music.generate(composition_plan: plan)

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('planned music data')
      expect(audio.text).to be_nil
    end

    it 'raises error when neither prompt nor composition_plan provided' do
      expect { music.generate }.to raise_error(
        ElevenRb::Errors::ValidationError,
        'Either prompt or composition_plan must be provided'
      )
    end

    it 'raises error when both prompt and composition_plan provided' do
      expect { music.generate('jazz', composition_plan: { sections: [] }) }.to raise_error(
        ElevenRb::Errors::ValidationError,
        'prompt and composition_plan are mutually exclusive'
      )
    end

    it 'includes optional params for prompt-based generation' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      music.generate('jazz', music_length_ms: 30_000, force_instrumental: true)

      expect(WebMock).to(have_requested(:post, %r{/v1/music\?})
        .with do |req|
          body = JSON.parse(req.body)
          body['music_length_ms'] == 30_000 &&
            body['force_instrumental'] == true &&
            body['prompt'] == 'jazz'
        end)
    end

    it 'includes respect_sections_durations for compose' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      music.generate(composition_plan: { sections: [] }, respect_sections_durations: false)

      expect(WebMock).to(have_requested(:post, %r{/v1/music\?})
        .with do |req|
          body = JSON.parse(req.body)
          body['respect_sections_durations'] == false &&
            body.key?('composition_plan')
        end)
    end

    it 'omits optional params when not provided' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      music.generate('jazz')

      expect(WebMock).to(have_requested(:post, %r{/v1/music\?})
        .with do |req|
          body = JSON.parse(req.body)
          !body.key?('music_length_ms') &&
            !body.key?('force_instrumental') &&
            !body.key?('respect_sections_durations')
        end)
    end

    it 'triggers on_audio_generated callback' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) { received_cost_info = cost_info }
      )

      client_with_callback.music.generate('epic orchestra')

      expect(received_cost_info).to include(:character_count, :estimated_cost)
    end

    it 'accepts custom output_format' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=pcm_44100',
        response_body: 'pcm audio'
      )

      audio = music.generate('jazz', output_format: 'pcm_44100')

      expect(audio.format).to eq('pcm_44100')
    end

    it 'accepts custom model_id' do
      stub_elevenlabs_binary_request(
        :post,
        '/music?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      music.generate('jazz', model_id: 'custom_model')

      expect(WebMock).to(have_requested(:post, %r{/v1/music\?})
        .with { |req| JSON.parse(req.body)['model_id'] == 'custom_model' })
    end
  end

  describe '#stream' do
    it 'raises error without a block' do
      expect { music.stream('jazz') }.to raise_error(ArgumentError, 'Block required for streaming')
    end

    it 'raises error when neither prompt nor composition_plan provided' do
      expect { music.stream { |_c| nil } }.to raise_error(
        ElevenRb::Errors::ValidationError,
        'Either prompt or composition_plan must be provided'
      )
    end

    it 'raises error when both prompt and composition_plan provided' do
      expect { music.stream('jazz', composition_plan: { sections: [] }) { |_c| nil } }.to raise_error(
        ElevenRb::Errors::ValidationError,
        'prompt and composition_plan are mutually exclusive'
      )
    end
  end

  describe '#create_plan' do
    it 'returns a hash' do
      stub_elevenlabs_request(
        :post,
        '/music/plan',
        response_body: { 'global_style' => 'jazz', 'sections' => [] }
      )

      result = music.create_plan('upbeat jazz')

      expect(result).to be_a(Hash)
      expect(result['global_style']).to eq('jazz')
    end

    it 'raises error for blank prompt' do
      expect { music.create_plan('') }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'raises error for nil prompt' do
      expect { music.create_plan(nil) }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'includes optional music_length_ms' do
      stub_elevenlabs_request(
        :post,
        '/music/plan',
        response_body: { 'sections' => [] }
      )

      music.create_plan('jazz', music_length_ms: 60_000)

      expect(WebMock).to(have_requested(:post, %r{/v1/music/plan})
        .with do |req|
          body = JSON.parse(req.body)
          body['music_length_ms'] == 60_000
        end)
    end

    it 'omits music_length_ms when not provided' do
      stub_elevenlabs_request(
        :post,
        '/music/plan',
        response_body: { 'sections' => [] }
      )

      music.create_plan('jazz')

      expect(WebMock).to(have_requested(:post, %r{/v1/music/plan})
        .with do |req|
          body = JSON.parse(req.body)
          !body.key?('music_length_ms')
        end)
    end

    it 'accepts custom model_id' do
      stub_elevenlabs_request(
        :post,
        '/music/plan',
        response_body: { 'sections' => [] }
      )

      music.create_plan('jazz', model_id: 'custom_model')

      expect(WebMock).to(have_requested(:post, %r{/v1/music/plan})
        .with { |req| JSON.parse(req.body)['model_id'] == 'custom_model' })
    end
  end
end
