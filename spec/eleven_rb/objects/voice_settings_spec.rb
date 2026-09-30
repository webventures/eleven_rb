# frozen_string_literal: true

RSpec.describe ElevenRb::Objects::VoiceSettings do
  describe '.for_model' do
    it 'returns exactly the historic defaults for eleven_multilingual_v2 (key order included)' do
      settings, dropped = described_class.for_model('eleven_multilingual_v2')

      expect(settings.to_a).to eq([[:stability, 0.5], [:similarity_boost, 0.75], [:style, 0.0],
                                   [:use_speaker_boost, true]])
      expect(dropped).to eq([])
    end

    it 'matches DEFAULTS.merge(overrides) for eleven_multilingual_v2 with symbol overrides' do
      overrides = { stability: 0.3, speed: 1.05 }
      settings, = described_class.for_model('eleven_multilingual_v2', overrides)

      expect(settings.to_a).to eq(described_class::DEFAULTS.merge(overrides).to_a)
    end

    it 'returns only stability and similarity_boost for eleven_v4' do
      settings, dropped = described_class.for_model('eleven_v4')

      expect(settings).to eq(stability: 0.5, similarity_boost: 0.75)
      expect(dropped).to eq([])
    end

    it 'drops override keys the model ignores and reports them' do
      settings, dropped = described_class.for_model('eleven_v4_turbo',
                                                    'stability' => 0.2, speed: 0.8, style: 0.1,
                                                    use_speaker_boost: false)

      expect(settings).to eq(stability: 0.2, similarity_boost: 0.75)
      expect(dropped).to eq(%i[speed style use_speaker_boost])
    end

    it 'keeps use_speaker_boost for eleven_v3_conversational' do
      settings, = described_class.for_model('eleven_v3_conversational')

      expect(settings).to eq(stability: 0.5, similarity_boost: 0.75, use_speaker_boost: true)
    end

    it 'passes unknown keys through on every model, after the supported ones, in caller order' do
      settings, dropped = described_class.for_model('eleven_v4', future_b: 2, speed: 0.9, future_a: 1)

      expect(settings.to_a).to eq([[:stability, 0.5], [:similarity_boost, 0.75], [:future_b, 2], [:future_a, 1]])
      expect(dropped).to eq(%i[speed])
    end

    it 'passes unknown keys through on eleven_multilingual_v2' do
      settings, dropped = described_class.for_model('eleven_multilingual_v2', 'future_field' => true)

      expect(settings[:future_field]).to be(true)
      expect(dropped).to eq([])
    end

    it 'does not report nil-valued unsupported overrides as dropped' do
      settings, dropped = described_class.for_model('eleven_v4', style: nil, speed: nil)

      expect(settings).to eq(stability: 0.5, similarity_boost: 0.75)
      expect(dropped).to eq([])
    end

    it 'removes nil values' do
      settings, dropped = described_class.for_model('eleven_multilingual_v2', style: nil)

      expect(settings).to eq(stability: 0.5, similarity_boost: 0.75, use_speaker_boost: true)
      expect(dropped).to eq([])
    end

    it 'accepts nil overrides' do
      settings, dropped = described_class.for_model('eleven_v3', nil)

      expect(settings).to eq(stability: 0.5, similarity_boost: 0.75)
      expect(dropped).to eq([])
    end
  end
end
