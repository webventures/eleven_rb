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
      expect(audio.model_id).to eq('eleven_v4')
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
      expect(received_cost_info[:model_id]).to eq('eleven_v4')
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
      long_input = [{ text: 'x' * 10_001, voice_id: 'v1' }]

      expect { dialogue.generate(long_input) }
        .to raise_error(ElevenRb::Errors::ValidationError, /exceeds maximum 10000 characters for eleven_v4/)
    end

    it 'caps eleven_v3 at 5,000 characters' do
      long_input = [{ text: 'x' * 5001, voice_id: 'v1' }]

      expect { dialogue.generate(long_input, model_id: 'eleven_v3') }
        .to raise_error(ElevenRb::Errors::ValidationError, /exceeds maximum 5000 characters for eleven_v3/)
    end

    it 'warns (but sends) above the recommended 2,000 characters' do
      stub_elevenlabs_binary_request(:post, '/text-to-dialogue?output_format=mp3_44100_128', response_body: 'audio')
      logger = double('logger', warn: nil)
      warn_client = test_client(logger: logger)

      audio = warn_client.dialogue.generate([{ text: 'x' * 2001, voice_id: 'v1' }])

      expect(audio.data).to eq('audio')
      expect(logger).to have_received(:warn).with(/2001 characters.*2000 or fewer/)
    end

    it 'does not warn at the recommended length' do
      stub_elevenlabs_binary_request(:post, '/text-to-dialogue?output_format=mp3_44100_128', response_body: 'audio')
      logger = double('logger', warn: nil)
      warn_client = test_client(logger: logger)

      warn_client.dialogue.generate([{ text: 'x' * 2000, voice_id: 'v1' }])

      expect(logger).not_to have_received(:warn)
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

  describe 'keyword coverage' do
    %i[generate generate_with_timestamps].each do |method_name|
      it "declares a keyword for every OPTIONAL_BODY_KEYS entry on ##{method_name}" do
        keywords = described_class.instance_method(method_name).parameters
                                  .filter_map { |type, name| name if %i[key keyreq].include?(type) }

        expect(keywords).to include(*described_class::OPTIONAL_BODY_KEYS)
      end
    end
  end

  describe 'request body' do
    let(:url) { 'https://api.elevenlabs.io/v1/text-to-dialogue?output_format=mp3_44100_128' }
    let(:input_body) { inputs.map { |i| { text: i[:text], voice_id: i[:voice_id] } } }

    it 'omits the new optional keys when not given' do
      expected = { inputs: input_body, model_id: 'eleven_v4', apply_text_normalization: 'auto' }.to_json
      stub = stub_request(:post, url).with(body: expected).to_return(status: 200, body: 'audio')

      dialogue.generate(inputs)

      expect(stub).to have_been_requested
    end

    it 'keeps the historic body for an explicit eleven_v3 call' do
      expected = {
        inputs: input_body, model_id: 'eleven_v3', apply_text_normalization: 'auto',
        language_code: 'en', settings: { stability: 0.5 }, seed: 42
      }.to_json
      stub = stub_request(:post, url).with(body: expected).to_return(status: 200, body: 'audio')

      dialogue.generate(inputs, model_id: 'eleven_v3', language_code: 'en', settings: { stability: 0.5 }, seed: 42)

      expect(stub).to have_been_requested
    end

    it 'sends the new optional keys and passes settings through unchanged' do
      locators = [{ pronunciation_dictionary_id: 'pd1', version_id: 'v1' }]
      expected = {
        inputs: input_body, model_id: 'eleven_v4', apply_text_normalization: 'auto',
        settings: { stability: 0.5, similarity: 0.8 },
        use_pvc_as_ivc: true,
        previous_text: 'Before.',
        future_text: 'After.',
        previous_request_ids: ['r1'],
        next_request_ids: ['r2'],
        pronunciation_dictionary_locators: locators
      }.to_json
      stub = stub_request(:post, url).with(body: expected)
                                     .to_return(status: 200, body: 'audio', headers: { 'request-id' => 'dlg_1' })

      audio = dialogue.generate(
        inputs,
        pronunciation_dictionary_locators: locators, next_request_ids: ['r2'], previous_request_ids: ['r1'],
        future_text: 'After.', previous_text: 'Before.', use_pvc_as_ivc: true,
        settings: { stability: 0.5, similarity: 0.8 }
      )

      expect(stub).to have_been_requested
      expect(audio.request_id).to eq('dlg_1')
    end
  end

  describe '#generate_with_timestamps' do
    let(:alignment) { { 'characters' => %w[W], 'character_start_times_seconds' => [0.0] } }
    let(:segments) do
      [{ 'voice_id' => 'voice_abc', 'start_time_seconds' => 0.0, 'end_time_seconds' => 1.2, 'dialogue_input_index' => 0 }]
    end

    before do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-dialogue/with-timestamps?output_format=mp3_44100_128')
        .with(body: hash_including('model_id' => 'eleven_v4', 'seed' => 5))
        .to_return(
          status: 200,
          body: { audio_base64: Base64.strict_encode64('dialogue bytes'), alignment: alignment,
                  normalized_alignment: alignment, voice_segments: segments }.to_json,
          headers: { 'Content-Type' => 'application/json', 'request-id' => 'dlg_ts' }
        )
    end

    it 'returns decoded audio, alignments, voice segments and the request id' do
      result = dialogue.generate_with_timestamps(inputs, seed: 5)

      expect(result.keys).to eq(%i[audio alignment normalized_alignment voice_segments request_id])
      expect(result[:audio].data).to eq('dialogue bytes')
      expect(result[:audio].request_id).to eq('dlg_ts')
      expect(result[:alignment]).to eq(alignment)
      expect(result[:normalized_alignment]).to eq(alignment)
      expect(result[:voice_segments]).to eq(segments)
      expect(result[:request_id]).to eq('dlg_ts')
    end

    it 'triggers the cost callback' do
      received = nil
      cb_client = test_client(on_audio_generated: ->(cost_info:, request_id:, **) { received = [cost_info, request_id] })

      cb_client.dialogue.generate_with_timestamps(inputs, seed: 5)

      expect(received.first[:model_id]).to eq('eleven_v4')
      expect(received.last).to eq('dlg_ts')
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
