# frozen_string_literal: true

require 'tempfile'

RSpec.describe ElevenRb::Resources::SpeechToSpeech do
  let(:client) { test_client }
  let(:sts) { client.sts }

  describe '#convert' do
    let(:audio_file) { Tempfile.new(['test_audio', '.mp3']) }

    before do
      audio_file.write('fake audio content')
      audio_file.rewind
    end

    after { audio_file.close! }

    it 'returns an audio object' do
      stub_elevenlabs_binary_request(
        :post,
        '/speech-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'converted audio data'
      )

      audio = sts.convert(audio_file, voice_id: 'voice123')

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('converted audio data')
      expect(audio.voice_id).to eq('voice123')
      expect(audio.model_id).to eq('eleven_english_sts_v2')
    end

    it 'accepts a file path' do
      stub_elevenlabs_binary_request(
        :post,
        '/speech-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'converted audio'
      )

      audio = sts.convert(audio_file.path, voice_id: 'voice123')

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('converted audio')
    end

    it 'sends correct model_id' do
      stub_elevenlabs_binary_request(
        :post,
        '/speech-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      sts.convert(audio_file, voice_id: 'voice123', model_id: 'eleven_english_sts_v2')

      expect(WebMock).to have_requested(:post, %r{/speech-to-speech/voice123})
    end

    it 'raises error for blank voice_id' do
      expect do
        sts.convert(audio_file, voice_id: '')
      end.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'raises error for non-existent file path' do
      expect do
        sts.convert('/nonexistent/file.mp3', voice_id: 'v1')
      end.to raise_error(ElevenRb::Errors::ValidationError, /File not found/)
    end

    it 'raises error for invalid input type' do
      expect do
        sts.convert(12_345, voice_id: 'v1')
      end.to raise_error(ArgumentError, /Expected file path or IO/)
    end

    it 'triggers on_audio_generated callback' do
      stub_elevenlabs_binary_request(
        :post,
        '/speech-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) { received_cost_info = cost_info }
      )

      client_with_callback.sts.convert(audio_file, voice_id: 'voice123')

      expect(received_cost_info).to include(:character_count, :estimated_cost, :model_id)
      expect(received_cost_info[:model_id]).to eq('eleven_english_sts_v2')
    end
  end

  describe 'client accessors' do
    it 'is accessible via client.speech_to_speech' do
      expect(client.speech_to_speech).to be_a(described_class)
    end

    it 'is accessible via client.sts alias' do
      expect(client.sts).to be_a(described_class)
      expect(client.sts).to eq(client.speech_to_speech)
    end
  end
end
