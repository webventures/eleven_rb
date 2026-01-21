# frozen_string_literal: true

RSpec.describe ElevenRb::Objects::Voice do
  describe '.from_response' do
    it 'creates a voice from API response' do
      response = {
        'voice_id' => 'v123',
        'name' => 'Test Voice',
        'description' => 'A test voice',
        'category' => 'professional',
        'labels' => {
          'gender' => 'female',
          'accent' => 'British',
          'language' => 'English'
        }
      }

      voice = described_class.from_response(response)

      expect(voice.voice_id).to eq('v123')
      expect(voice.name).to eq('Test Voice')
      expect(voice.gender).to eq('female')
      expect(voice.accent).to eq('British')
      expect(voice.language).to eq('English')
    end
  end

  describe '#provider' do
    it 'returns :elevenlabs' do
      voice = described_class.from_response({})
      expect(voice.provider).to eq(:elevenlabs)
    end
  end

  describe '#display_name' do
    it 'returns formatted name with metadata' do
      voice = described_class.from_response({
                                              'name' => 'Maria',
                                              'labels' => { 'gender' => 'female', 'accent' => 'Spanish' }
                                            })

      expect(voice.display_name).to eq('Maria (female) - Spanish')
    end
  end

  describe '#banned?' do
    it 'returns true when safety_control is BAN' do
      voice = described_class.from_response({ 'safety_control' => 'BAN' })
      expect(voice.banned?).to be true
    end

    it 'returns false otherwise' do
      voice = described_class.from_response({})
      expect(voice.banned?).to be false
    end
  end
end
