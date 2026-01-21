# frozen_string_literal: true

RSpec.describe ElevenRb::Client do
  describe '#initialize' do
    it 'creates a client with an API key' do
      client = described_class.new(api_key: 'test-key')
      expect(client.config.api_key).to eq('test-key')
    end

    it 'raises an error without an API key' do
      expect { described_class.new }.to raise_error(ElevenRb::Errors::ConfigurationError)
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

    it 'memoizes resource instances' do
      expect(client.voices).to eq(client.voices)
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
