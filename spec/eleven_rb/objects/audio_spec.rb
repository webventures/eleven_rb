# frozen_string_literal: true

RSpec.describe ElevenRb::Objects::Audio do
  let(:audio) do
    described_class.new(
      data: 'fake audio data',
      format: 'mp3_44100_128',
      voice_id: 'voice123',
      text: 'Hello world'
    )
  end

  describe '#bytes' do
    it 'returns the data size' do
      expect(audio.bytes).to eq(15)
    end
  end

  describe '#kilobytes' do
    it 'returns size in KB' do
      expect(audio.kilobytes).to be_within(0.01).of(0.0146)
    end
  end

  describe '#content_type' do
    it 'returns audio/mpeg for mp3' do
      expect(audio.content_type).to eq('audio/mpeg')
    end

    it 'returns correct types for other formats' do
      pcm_audio = described_class.new(data: '', format: 'pcm_16000', voice_id: '', text: '')
      expect(pcm_audio.content_type).to eq('audio/pcm')
    end
  end

  describe '#extension' do
    it 'returns mp3 for mp3 format' do
      expect(audio.extension).to eq('mp3')
    end
  end

  describe '#character_count' do
    it 'returns the text length' do
      expect(audio.character_count).to eq(11)
    end
  end

  describe '#save_to_file' do
    it 'writes data to file' do
      path = "/tmp/test_audio_#{Time.now.to_i}.mp3"
      audio.save_to_file(path)

      expect(File.read(path)).to eq('fake audio data')
      File.delete(path)
    end
  end

  describe '#to_io' do
    it 'returns a StringIO' do
      io = audio.to_io
      expect(io).to be_a(StringIO)
      expect(io.read).to eq('fake audio data')
    end
  end

  describe '#present?' do
    it 'returns true when data exists' do
      expect(audio.present?).to be true
    end

    it 'returns false when data is empty' do
      empty_audio = described_class.new(data: '', format: '', voice_id: '', text: '')
      expect(empty_audio.present?).to be false
    end
  end
end
