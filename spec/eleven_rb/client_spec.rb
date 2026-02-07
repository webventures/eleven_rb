# frozen_string_literal: true

RSpec.describe ElevenRb::Client do
  describe '#initialize' do
    it 'creates a client with an API key' do
      client = described_class.new(api_key: 'test-key')
      expect(client.config.api_key).to eq('test-key')
    end

    it 'does not raise without an API key until first API call' do
      client = described_class.new
      expect(client).to be_a(described_class)

      stub_request(:get, 'https://api.elevenlabs.io/v1/voices')
      expect { client.voices.list }.to raise_error(ElevenRb::Errors::ConfigurationError)
    end

    it 'accepts configuration options' do
      client = described_class.new(
        api_key: 'test-key',
        timeout: 60,
        max_retries: 5
      )

      expect(client.config.timeout).to eq(60)
      expect(client.config.max_retries).to eq(5)
    end

    it 'accepts callbacks' do
      callback_called = false
      client = described_class.new(
        api_key: 'test-key',
        on_request: ->(**) { callback_called = true }
      )

      expect(client.config.on_request).to be_a(Proc)
    end
  end

  describe 'resource accessors' do
    let(:client) { described_class.new(api_key: 'test-key') }

    it 'provides voices resource' do
      expect(client.voices).to be_a(ElevenRb::Resources::Voices)
    end

    it 'provides tts resource' do
      expect(client.tts).to be_a(ElevenRb::Resources::TextToSpeech)
    end

    it 'provides voice_library resource' do
      expect(client.voice_library).to be_a(ElevenRb::Resources::VoiceLibrary)
    end

    it 'provides models resource' do
      expect(client.models).to be_a(ElevenRb::Resources::Models)
    end

    it 'provides user resource' do
      expect(client.user).to be_a(ElevenRb::Resources::User)
    end

    it 'provides voice_slots manager' do
      expect(client.voice_slots).to be_a(ElevenRb::VoiceSlotManager)
    end

    it 'provides sound_effects resource' do
      expect(client.sound_effects).to be_a(ElevenRb::Resources::SoundEffects)
    end

    it 'memoizes resource instances' do
      expect(client.voices).to eq(client.voices)
    end
  end

  describe '#configured?' do
    it 'returns true when API key is present' do
      client = described_class.new(api_key: 'test-key')
      expect(client.configured?).to be true
    end

    it 'returns false without an API key' do
      client = described_class.new
      expect(client.configured?).to be false
    end

    it 'returns false with an empty string API key' do
      client = described_class.new(api_key: '')
      expect(client.configured?).to be false
    end
  end

  describe '#generate_sound_effect' do
    let(:client) { described_class.new(api_key: 'test-key') }

    it 'delegates to sound_effects.generate' do
      stub_elevenlabs_binary_request(:post, '/sound-generation?output_format=mp3_44100_128',
                                     response_body: 'sfx audio data')

      audio = client.generate_sound_effect('explosion')
      expect(audio).to be_a(ElevenRb::Objects::Audio)
    end
  end

  describe '#generate_speech' do
    let(:client) { described_class.new(api_key: 'test-key') }

    it 'delegates to tts.generate' do
      stub_elevenlabs_binary_request(:post, '/text-to-speech/voice123',
                                     query: { 'output_format' => 'mp3_44100_128' },
                                     response_body: 'audio data')

      audio = client.generate_speech('Hello', voice_id: 'voice123')
      expect(audio).to be_a(ElevenRb::Objects::Audio)
    end
  end
end
