# frozen_string_literal: true

RSpec.describe ElevenRb do
  it 'has a version number' do
    expect(ElevenRb::VERSION).not_to be_nil
  end

  describe '.client' do
    before { described_class.reset! }

    it 'returns a client instance' do
      stub_request(:any, /elevenlabs/).to_return(status: 200, body: '{}')

      client = described_class.client(api_key: 'test-key')
      expect(client).to be_a(ElevenRb::Client)
    end

    it 'returns the same client on subsequent calls' do
      client1 = described_class.client(api_key: 'test-key')
      client2 = described_class.client
      expect(client1).to eq(client2)
    end
  end

  describe '.reset!' do
    it 'clears the cached client' do
      client1 = described_class.client(api_key: 'test-key')
      described_class.reset!
      client2 = described_class.client(api_key: 'test-key')

      expect(client1).not_to eq(client2)
    end
  end
end
