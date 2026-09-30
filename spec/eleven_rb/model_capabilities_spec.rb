# frozen_string_literal: true

RSpec.describe ElevenRb::ModelCapabilities do
  all_five = %i[stability similarity_boost style use_speaker_boost speed]

  {
    'eleven_v4' => [%i[stability similarity_boost], 10_000, false, true, true],
    'eleven_v4_turbo' => [%i[stability similarity_boost], 10_000, false, true, true],
    'eleven_v3_conversational' => [%i[stability similarity_boost use_speaker_boost], 5_000, false, true, true],
    'eleven_v3' => [%i[stability similarity_boost], 5_000, false, true, true],
    'eleven_flash_v2_5' => [all_five, 40_000, true, false, true],
    'eleven_turbo_v2_5' => [all_five, 40_000, true, false, true],
    'eleven_flash_v2' => [all_five, 30_000, true, false, true],
    'eleven_turbo_v2' => [all_five, 30_000, true, false, true],
    'eleven_multilingual_v2' => [all_five, 10_000, true, false, true],
    'eleven_monolingual_v1' => [all_five, 10_000, true, false, true],
    'eleven_multilingual_v1' => [all_five, 10_000, true, false, true],
    'some_future_model' => [all_five, 10_000, true, false, true]
  }.each do |model_id, (settings, max_len, ssml, tags, continuity)|
    context model_id do
      subject(:caps) { described_class.for(model_id) }

      it 'reports its capabilities' do
        expect(caps.voice_settings).to eq(settings)
        expect(caps.max_text_length).to eq(max_len)
        expect(caps.ssml_break).to be(ssml)
        expect(caps.audio_tags).to be(tags)
        expect(caps.continuity).to be(continuity)
      end

      it 'agrees with the helper methods' do
        expect(described_class.supported_voice_settings(model_id)).to eq(settings)
        expect(described_class.max_text_length(model_id)).to eq(max_len)
        expect(described_class.supports?(model_id, :ssml_break)).to be(ssml)
        expect(described_class.supports?(model_id, :audio_tags)).to be(tags)
        expect(described_class.supports?(model_id, 'continuity')).to be(continuity)
      end
    end
  end

  it 'returns frozen records' do
    caps = described_class.for('eleven_v4')
    expect(caps).to be_frozen
    expect(caps.voice_settings).to be_frozen
  end

  it 'exposes predicate readers' do
    caps = described_class.for('eleven_v4')
    expect(caps.audio_tags?).to be(true)
    expect(caps.ssml_break?).to be(false)
    expect(caps.continuity?).to be(true)
  end

  it 'treats nil and symbols like strings' do
    expect(described_class.max_text_length(nil)).to eq(10_000)
    expect(described_class.max_text_length(:eleven_v3)).to eq(5_000)
  end

  it 'rejects unknown features' do
    expect { described_class.supports?('eleven_v4', :teleport) }.to raise_error(ArgumentError, /teleport/)
  end
end
