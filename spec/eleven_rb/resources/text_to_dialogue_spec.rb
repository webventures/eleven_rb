# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::TextToDialogue do
  let(:client) { test_client }
  let(:dialogue) { client.text_to_dialogue }
  let(:inputs) do
    [
      { text: '[excited] Welcome to the show!', voice_id: 'voice_abc' },
      { text: '[laughs] Thanks for having me.', voice_id: 'voice_xyz' }
    ]
  end

  describe '#generate' do
    it 'returns an audio object' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-dialogue?output_format=mp3_44100_128',
        response_body: 'dialogue audio data'
      )

      audio = dialogue.generate(inputs)

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('dialogue audio data')
      expect(audio.voice_id).to eq('voice_abc')
      expect(audio.model_id).to eq('eleven_v3')
    end

    it 'accepts optional parameters' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-dialogue?output_format=mp3_44100_192',
        response_body: 'audio'
      )

      audio = dialogue.generate(
        inputs,
        language_code: 'en',
        settings: { stability: 0.5 },
        seed: 42,
        output_format: 'mp3_44100_192'
      )

      expect(audio).to be_a(ElevenRb::Objects::Audio)
    end

    it 'triggers on_audio_generated callback' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-dialogue?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: lambda { |audio:, voice_id:, text:, cost_info:|
          received_cost_info = cost_info
        }
      )

      client_with_callback.text_to_dialogue.generate(inputs)

      expect(received_cost_info).to include(:character_count, :estimated_cost, :model_id)
      expect(received_cost_info[:model_id]).to eq('eleven_v3')
      total_chars = inputs.sum { |i| i[:text].length }
      expect(received_cost_info[:character_count]).to eq(total_chars)
    end
  end

  describe 'validation' do
    it 'raises error for nil inputs' do
      expect { dialogue.generate(nil) }
        .to raise_error(ElevenRb::Errors::ValidationError, /non-empty array/)
    end

    it 'raises error for empty inputs' do
      expect { dialogue.generate([]) }
        .to raise_error(ElevenRb::Errors::ValidationError, /non-empty array/)
    end

    it 'raises error for missing text in input' do
      expect { dialogue.generate([{ text: '', voice_id: 'v1' }]) }
        .to raise_error(ElevenRb::Errors::ValidationError, /text.*blank/)
    end

    it 'raises error for missing voice_id in input' do
      expect { dialogue.generate([{ text: 'Hello', voice_id: '' }]) }
        .to raise_error(ElevenRb::Errors::ValidationError, /voice_id.*blank/)
    end

    it 'raises error for too many unique voices' do
      many_inputs = (1..11).map do |i|
        { text: "Line #{i}", voice_id: "voice_#{i}" }
      end

      expect { dialogue.generate(many_inputs) }
        .to raise_error(ElevenRb::Errors::ValidationError, /Maximum 10/)
    end

    it 'raises error for text exceeding max length' do
      long_input = [{ text: 'x' * 5001, voice_id: 'v1' }]

      expect { dialogue.generate(long_input) }
        .to raise_error(ElevenRb::Errors::ValidationError, /exceeds maximum/)
    end

    it 'allows 10 unique voices' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-dialogue?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      ten_inputs = (1..10).map do |i|
        { text: "Line #{i}", voice_id: "voice_#{i}" }
      end

      expect { dialogue.generate(ten_inputs) }.not_to raise_error
    end
  end

  describe 'client accessors' do
    it 'is accessible via client.text_to_dialogue' do
      expect(client.text_to_dialogue).to be_a(described_class)
    end

    it 'is accessible via client.dialogue alias' do
      expect(client.dialogue).to be_a(described_class)
      expect(client.dialogue).to eq(client.text_to_dialogue)
    end
  end
end
