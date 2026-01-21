# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::TextToSpeech do
  let(:client) { test_client }
  let(:tts) { client.tts }

  describe "#generate" do
    it "returns an audio object" do
      stub_elevenlabs_binary_request(
        :post,
        "/text-to-speech/voice123?output_format=mp3_44100_128",
        response_body: "fake audio data"
      )

      audio = tts.generate("Hello world", voice_id: "voice123")

      expect(audio).to be_a(ElevenRb::Objects::Audio)
      expect(audio.data).to eq("fake audio data")
      expect(audio.voice_id).to eq("voice123")
      expect(audio.text).to eq("Hello world")
    end

    it "raises error for blank text" do
      expect { tts.generate("", voice_id: "v1") }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it "raises error for blank voice_id" do
      expect { tts.generate("Hello", voice_id: "") }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it "raises error for text exceeding max length" do
      long_text = "a" * 5001
      expect { tts.generate(long_text, voice_id: "v1") }.to raise_error(ElevenRb::Errors::ValidationError)
    end

    it "triggers on_audio_generated callback" do
      stub_elevenlabs_binary_request(
        :post,
        "/text-to-speech/voice123?output_format=mp3_44100_128",
        response_body: "audio"
      )

      received_cost_info = nil
      client_with_callback = test_client(
        on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) { received_cost_info = cost_info }
      )

      client_with_callback.tts.generate("Hello", voice_id: "voice123")

      expect(received_cost_info).to include(:character_count, :estimated_cost)
    end
  end

  describe "#stream" do
    it "raises error without block" do
      expect { tts.stream("Hello", voice_id: "v1") }.to raise_error(ArgumentError)
    end
  end
end
