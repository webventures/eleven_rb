# frozen_string_literal: true

RSpec.describe ElevenRb::VoiceSlotManager do
  let(:client) { test_client }
  let(:manager) { client.voice_slots }

  describe '#status' do
    before do
      stub_elevenlabs_request(:get, '/user/subscription', response_body: {
                                'voice_limit' => 10,
                                'character_count' => 1000,
                                'character_limit' => 10_000
                              })
      stub_elevenlabs_request(:get, '/voices', response_body: {
                                'voices' => [
                                  { 'voice_id' => 'v1' },
                                  { 'voice_id' => 'v2' },
                                  { 'voice_id' => 'v3' }
                                ]
                              })
    end

    it 'returns slot status' do
      status = manager.status

      expect(status[:used]).to eq(3)
      expect(status[:limit]).to eq(10)
      expect(status[:available]).to eq(7)
      expect(status[:full]).to be false
    end
  end

  describe '#track_usage' do
    it 'tracks voice usage times' do
      manager.track_usage('voice1')
      manager.track_usage('voice2')

      # Can't directly test internal state, but verify it doesn't error
      expect { manager.track_usage('voice3') }.not_to raise_error
    end
  end

  describe '#in_account?' do
    before do
      stub_elevenlabs_request(:get, '/voices', response_body: {
                                'voices' => [{ 'voice_id' => 'v1' }, { 'voice_id' => 'v2' }]
                              })
    end

    it 'returns true for existing voice' do
      expect(manager.in_account?('v1')).to be true
    end

    it 'returns false for missing voice' do
      expect(manager.in_account?('v999')).to be false
    end
  end

  describe '#find_in_account' do
    before do
      stub_elevenlabs_request(:get, '/voices', response_body: {
                                'voices' => [
                                  { 'voice_id' => 'v1', 'name' => 'Voice 1' }
                                ]
                              })
    end

    it 'returns the voice if found' do
      voice = manager.find_in_account('v1')
      expect(voice.voice_id).to eq('v1')
    end

    it 'returns nil if not found' do
      expect(manager.find_in_account('v999')).to be_nil
    end
  end

  describe '#reset_tracking!' do
    it 'clears tracking data' do
      manager.track_usage('voice1')
      manager.reset_tracking!
      # Verify it doesn't error after reset
      expect { manager.track_usage('voice1') }.not_to raise_error
    end
  end
end
