# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::Voices do
  let(:client) { test_client }
  let(:voices) { client.voices }

  describe '#list' do
    it 'returns a voice collection' do
      stub_elevenlabs_request(:get, '/voices', response_body: {
                                'voices' => [
                                  { 'voice_id' => 'v1', 'name' => 'Voice 1' },
                                  { 'voice_id' => 'v2', 'name' => 'Voice 2' }
                                ]
                              })

      result = voices.list

      expect(result).to be_a(ElevenRb::Collections::VoiceCollection)
      expect(result.size).to eq(2)
    end
  end

  describe '#find' do
    it 'returns a voice object' do
      stub_elevenlabs_request(:get, '/voices/voice123', response_body: {
                                'voice_id' => 'voice123',
                                'name' => 'Test Voice',
                                'labels' => { 'gender' => 'male', 'language' => 'Spanish' }
                              })

      voice = voices.find('voice123')

      expect(voice).to be_a(ElevenRb::Objects::Voice)
      expect(voice.voice_id).to eq('voice123')
      expect(voice.name).to eq('Test Voice')
      expect(voice.gender).to eq('male')
    end

    it 'raises error for blank voice_id' do
      expect { voices.find('') }.to raise_error(ElevenRb::Errors::ValidationError)
      expect { voices.find(nil) }.to raise_error(ElevenRb::Errors::ValidationError)
    end
  end

  describe '#destroy' do
    it 'returns true on success' do
      stub_elevenlabs_request(:delete, '/voices/voice123', response_body: { 'status' => 'ok' })

      result = voices.destroy('voice123')

      expect(result).to be true
    end

    it 'raises error for blank voice_id' do
      expect { voices.destroy('') }.to raise_error(ElevenRb::Errors::ValidationError)
    end
  end
end
