# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::TextToSpeech do
  let(:client) { test_client }
  let(:tts) { client.tts }

  describe '#generate' do
    it 'returns an audio object' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'fake audio data'
      )

      audio = tts.generate('Hello world', voice_id: 'voice123')

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq('fake audio data')
      expect(audio.voice_id).to eq('voice123')
      expect(audio.text).to eq('Hello world')
    end

    it 'raises error for blank text' do
      expect { tts.generate('', voice_id: 'v1') }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'raises error for blank voice_id' do
      expect { tts.generate('Hello', voice_id: '') }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'raises error for text exceeding max length' do
      long_text = 'a' * 10_001
      expect { tts.generate(long_text, voice_id: 'v1') }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it 'triggers on_audio_generated callback' do
      stub_elevenlabs_binary_request(
        :post,
        '/text-to-speech/voice123?output_format=mp3_44100_128',
        response_body: 'audio'
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) { received_cost_info = cost_info }
      )

      client_with_callback.tts.generate('Hello', voice_id: 'voice123')

      expect(received_cost_info).to include(:character_count, :estimated_cost)
    end
  end

  describe '#stream' do
    it 'raises error without block' do
      expect { tts.stream('Hello', voice_id: 'v1') }.to raise_error(ArgumentError)
    end

    it 'streams with the shared body builder and optional kwargs' do
      stub = stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/voice123/stream?output_format=mp3_44100_128')
             .with(body: {
               text: 'Hi', model_id: 'eleven_v4',
               voice_settings: { stability: 0.5, similarity_boost: 0.75 },
               seed: 3, next_text: 'Bye'
             }.to_json)
             .to_return(status: 200, body: 'chunk')

      tts.stream('Hi', voice_id: 'voice123', model_id: 'eleven_v4', seed: 3, next_text: 'Bye') { |_c| nil }

      expect(stub).to have_been_requested
    end

    it 'passes request_id: nil to on_audio_generated' do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/voice123/stream?output_format=mp3_44100_128')
        .to_return(status: 200, body: 'chunk')

      received = nil
      streaming_client = test_client(on_audio_generated: ->(**kwargs) { received = kwargs })
      streaming_client.tts.stream('Hi', voice_id: 'voice123') { |_c| nil }

      expect(received).to include(audio: nil, request_id: nil)
    end
  end

  describe 'keyword coverage' do
    %i[generate stream generate_with_timestamps].each do |method_name|
      it "declares a keyword for every OPTIONAL_BODY_KEYS entry on ##{method_name}" do
        keywords = described_class.instance_method(method_name).parameters
                                  .filter_map { |type, name| name if %i[key keyreq].include?(type) }

        expect(keywords).to include(*described_class::OPTIONAL_BODY_KEYS)
      end
    end
  end

  describe 'request body' do
    let(:tts_url) { 'https://api.elevenlabs.io/v1/text-to-speech/voice123?output_format=mp3_44100_128' }

    def stub_tts(body_json)
      stub_request(:post, tts_url).with(body: body_json).to_return(status: 200, body: 'audio')
    end

    it 'sends a byte-identical default body for eleven_multilingual_v2' do
      expected = '{"text":"Hello world","model_id":"eleven_multilingual_v2",' \
                 '"voice_settings":{"stability":0.5,"similarity_boost":0.75,"style":0.0,"use_speaker_boost":true}}'
      stub = stub_tts(expected)

      tts.generate('Hello world', voice_id: 'voice123')

      expect(stub).to have_been_requested
    end

    it 'keeps caller overrides and extra supported keys (speed) for eleven_multilingual_v2' do
      expected = {
        text: 'Hi', model_id: 'eleven_multilingual_v2',
        voice_settings: { stability: 0.3, similarity_boost: 0.75, style: 0.0, use_speaker_boost: true, speed: 1.05 }
      }.to_json
      stub = stub_tts(expected)

      audio = tts.generate('Hi', voice_id: 'voice123', voice_settings: { stability: 0.3, speed: 1.05 })

      expect(stub).to have_been_requested
      expect(audio.dropped_settings).to eq([])
    end

    it 'omits every optional key when not given' do
      stub = stub_request(:post, tts_url).to_return(status: 200, body: 'audio')

      tts.generate('Hi', voice_id: 'voice123')

      expect(stub.with { |req| JSON.parse(req.body).keys == %w[text model_id voice_settings] }).to have_been_requested
    end

    it 'adds optional keys after voice_settings in the documented order' do
      locators = [{ pronunciation_dictionary_id: 'pd1', version_id: 'v1' }]
      expected = {
        text: 'Hi', model_id: 'eleven_v4',
        voice_settings: { stability: 0.5, similarity_boost: 0.75 },
        language_code: 'en',
        apply_text_normalization: 'off',
        seed: 42,
        previous_text: 'Before.',
        next_text: 'After.',
        previous_request_ids: ['r1'],
        next_request_ids: ['r2'],
        pronunciation_dictionary_locators: locators,
        use_pvc_as_ivc: true
      }.to_json
      stub = stub_tts(expected)

      tts.generate(
        'Hi',
        voice_id: 'voice123', model_id: 'eleven_v4',
        use_pvc_as_ivc: true, pronunciation_dictionary_locators: locators,
        next_request_ids: ['r2'], previous_request_ids: ['r1'],
        next_text: 'After.', previous_text: 'Before.', seed: 42,
        apply_text_normalization: 'off', language_code: 'en'
      )

      expect(stub).to have_been_requested
    end

    it 'sends only a false (not nil) optional value' do
      stub = stub_tts({
        text: 'Hi', model_id: 'eleven_multilingual_v2',
        voice_settings: { stability: 0.5, similarity_boost: 0.75, style: 0.0, use_speaker_boost: true },
        use_pvc_as_ivc: false
      }.to_json)

      tts.generate('Hi', voice_id: 'voice123', use_pvc_as_ivc: false, seed: nil)

      expect(stub).to have_been_requested
    end

    it 'rejects unknown keywords' do
      expect { tts.generate('Hi', voice_id: 'voice123', bogus: 1) }.to raise_error(ArgumentError)
    end
  end

  describe 'Eleven v4 voice settings' do
    let(:tts_url) { 'https://api.elevenlabs.io/v1/text-to-speech/voice123?output_format=mp3_44100_128' }

    it 'sends only stability and similarity_boost by default' do
      stub = stub_request(:post, tts_url)
             .with(body: {
               text: 'Hi', model_id: 'eleven_v4',
               voice_settings: { stability: 0.5, similarity_boost: 0.75 }
             }.to_json)
             .to_return(status: 200, body: 'audio')

      audio = tts.generate('Hi', voice_id: 'voice123', model_id: 'eleven_v4')

      expect(stub).to have_been_requested
      expect(audio.dropped_settings).to eq([])
    end

    it 'drops unsupported settings, logs a warning and reports them on the audio' do
      logger = double('logger', warn: nil)
      v4_client = test_client(logger: logger)
      stub = stub_request(:post, tts_url)
             .with(body: {
               text: 'Hi', model_id: 'eleven_v4',
               voice_settings: { stability: 0.4, similarity_boost: 0.75 }
             }.to_json)
             .to_return(status: 200, body: 'audio')

      audio = v4_client.tts.generate(
        'Hi',
        voice_id: 'voice123', model_id: 'eleven_v4',
        voice_settings: { 'stability' => 0.4, speed: 0.9, style: 0.2 }
      )

      expect(stub).to have_been_requested
      expect(audio.dropped_settings).to eq(%i[speed style])
      expect(logger).to have_received(:warn).with(/speed, style.*eleven_v4/)
    end

    it 'raises in strict mode, naming the model and keys' do
      strict = test_client(strict_voice_settings: true)

      expect do
        strict.tts.generate('Hi', voice_id: 'voice123', model_id: 'eleven_v4', voice_settings: { speed: 0.9 })
      end.to raise_error(ElevenRb::Errors::ValidationError, /speed.*eleven_v4/)
    end

    it 'does not raise in strict mode when nothing is dropped' do
      stub_request(:post, tts_url).to_return(status: 200, body: 'audio')
      strict = test_client(strict_voice_settings: true)

      expect { strict.tts.generate('Hi', voice_id: 'voice123', model_id: 'eleven_v4') }.not_to raise_error
    end
  end

  describe 'per-model text cap' do
    it 'rejects 5,001 characters on eleven_v3' do
      expect { tts.generate('a' * 5001, voice_id: 'v1', model_id: 'eleven_v3') }
        .to raise_error(ElevenRb::Errors::ValidationError, /5000 characters for eleven_v3/)
    end

    it 'accepts 5,001 characters on eleven_v4' do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/v1?output_format=mp3_44100_128')
        .to_return(status: 200, body: 'audio')

      expect { tts.generate('a' * 5001, voice_id: 'v1', model_id: 'eleven_v4') }.not_to raise_error
    end

    it 'keeps MAX_TEXT_LENGTH defined for compatibility' do
      expect(described_class::MAX_TEXT_LENGTH).to eq(5000)
    end
  end

  describe 'response metadata' do
    it 'reads request-id and character-cost from the response headers' do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/voice123?output_format=mp3_44100_128')
        .to_return(
          status: 200, body: 'audio',
          headers: { 'Content-Type' => 'audio/mpeg', 'request-id' => 'req_123', 'character-cost' => '42',
                     'history-item-id' => 'hist_1' }
        )

      audio = tts.generate('Hi', voice_id: 'voice123')

      expect(audio.request_id).to eq('req_123')
      expect(audio.character_cost).to eq(42)
    end

    it 'leaves request_id and character_cost nil when the headers are absent' do
      stub_elevenlabs_binary_request(:post, '/text-to-speech/voice123?output_format=mp3_44100_128',
                                     response_body: 'audio')

      audio = tts.generate('Hi', voice_id: 'voice123')

      expect(audio.request_id).to be_nil
      expect(audio.character_cost).to be_nil
    end

    it 'passes request_id to on_audio_generated callbacks that accept it' do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/voice123?output_format=mp3_44100_128')
        .to_return(status: 200, body: 'audio', headers: { 'request-id' => 'req_9' })

      received = nil
      cb_client = test_client(on_audio_generated: ->(request_id:, **) { received = request_id })
      cb_client.tts.generate('Hi', voice_id: 'voice123')

      expect(received).to eq('req_9')
    end
  end

  describe '#generate_with_timestamps' do
    let(:alignment) { { 'characters' => %w[H i], 'character_start_times_seconds' => [0.0, 0.1] } }
    let(:normalized) { { 'characters' => %w[h i], 'character_start_times_seconds' => [0.0, 0.1] } }

    before do
      stub_request(:post, 'https://api.elevenlabs.io/v1/text-to-speech/voice123/with-timestamps?output_format=mp3_44100_128')
        .with(body: {
          text: 'Hi', model_id: 'eleven_v4',
          voice_settings: { stability: 0.5, similarity_boost: 0.75 },
          seed: 7
        }.to_json)
        .to_return(
          status: 200,
          body: { audio_base64: Base64.strict_encode64('raw audio'), alignment: alignment,
                  normalized_alignment: normalized }.to_json,
          headers: { 'Content-Type' => 'application/json', 'request-id' => 'req_ts', 'character-cost' => '2' }
        )
    end

    it 'returns audio, both alignments and the response metadata' do
      result = tts.generate_with_timestamps('Hi', voice_id: 'voice123', model_id: 'eleven_v4', seed: 7)

      expect(result.keys).to eq(%i[audio alignment normalized_alignment request_id character_cost])
      expect(result[:audio].data).to eq('raw audio')
      expect(result[:audio].request_id).to eq('req_ts')
      expect(result[:alignment]).to eq(alignment)
      expect(result[:normalized_alignment]).to eq(normalized)
      expect(result[:request_id]).to eq('req_ts')
      expect(result[:character_cost]).to eq(2)
    end
  end
end
