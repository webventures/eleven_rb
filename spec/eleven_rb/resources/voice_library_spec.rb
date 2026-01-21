# frozen_string_literal: true

RSpec.describe ElevenRb::Resources::VoiceLibrary do
  let(:client) { test_client }
  let(:library) { client.voice_library }

  describe "#search" do
    it "returns a library voice collection" do
      stub_elevenlabs_request(:get, "/shared-voices",
        query: { "page_size" => "30" },
        response_body: {
          "voices" => [
            { "voice_id" => "v1", "name" => "Voice 1", "public_owner_id" => "user1" },
            { "voice_id" => "v2", "name" => "Voice 2", "public_owner_id" => "user2" }
          ],
          "has_more" => true,
          "last_sort_id" => "abc123"
        })

      result = library.search

      expect(result).to be_a(ElevenRb::Collections::LibraryVoiceCollection)
      expect(result.size).to eq(2)
      expect(result.has_more?).to be true
      expect(result.next_cursor).to eq("abc123")
    end

    it "passes search parameters" do
      stub = stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
        .with(query: hash_including("language" => "Spanish", "gender" => "female"))
        .to_return(status: 200, body: { "voices" => [] }.to_json)

      library.search(language: "Spanish", gender: "female")

      expect(stub).to have_been_requested
    end
  end

  describe "#add" do
    it "adds a voice from the library" do
      stub_elevenlabs_request(
        :post,
        "/voices/add/user123/voice456",
        response_body: { "voice_id" => "new_voice_id" }
      )

      voice = library.add(
        public_user_id: "user123",
        voice_id: "voice456",
        name: "My Voice"
      )

      expect(voice).to be_a(ElevenRb::Objects::Voice)
      expect(voice.voice_id).to eq("new_voice_id")
    end

    it "raises error for blank parameters" do
      expect { library.add(public_user_id: "", voice_id: "v1", name: "Test") }
        .to raise_error(ElevenRb::Errors::ValidationError)
    end
  end
end
