# frozen_string_literal: true

RSpec.describe ElevenRb::Configuration do
  describe '#initialize' do
    it 'sets default values' do
      config = described_class.new(api_key: 'test-key')

      expect(config.base_url).to eq('https://api.elevenlabs.io/v1')
      expect(config.timeout).to eq(120)
      expect(config.open_timeout).to eq(10)
      expect(config.max_retries).to eq(3)
    end

    it 'allows overriding defaults' do
      config = described_class.new(
        api_key: 'test-key',
        timeout: 60,
        max_retries: 5
      )

      expect(config.timeout).to eq(60)
      expect(config.max_retries).to eq(5)
    end

    it 'accepts callback options' do
      callback = ->(**) {}
      config = described_class.new(
        api_key: 'test-key',
        on_request: callback
      )

      expect(config.on_request).to eq(callback)
    end
  end

  describe '#validate!' do
    it 'raises error when api_key is nil' do
      config = described_class.new
      expect { config.validate! }.to raise_error(ElevenRb::Errors::ConfigurationError)
    end

    it 'raises error when api_key is empty' do
      config = described_class.new(api_key: '')
      expect { config.validate! }.to raise_error(ElevenRb::Errors::ConfigurationError)
    end

    it 'returns true when valid' do
      config = described_class.new(api_key: 'test-key')
      expect(config.validate!).to be true
    end
  end

  describe '#to_h' do
    it 'redacts the API key' do
      config = described_class.new(api_key: 'secret-key')
      hash = config.to_h

      expect(hash[:api_key]).to eq('[REDACTED]')
    end
  end

  describe '#trigger' do
    it 'calls the callback with kwargs' do
      received_args = nil
      config = described_class.new(
        api_key: 'test-key',
        on_request: ->(method:, path:, body:) { received_args = { method: method, path: path, body: body } }
      )

      config.trigger(:on_request, method: :get, path: '/test', body: nil)

      expect(received_args).to eq({ method: :get, path: '/test', body: nil })
    end

    it 'does nothing when callback is not set' do
      config = described_class.new(api_key: 'test-key')
      expect { config.trigger(:on_request, method: :get, path: '/test', body: nil) }.not_to raise_error
    end

    it 'catches and logs callback errors' do
      config = described_class.new(
        api_key: 'test-key',
        on_request: ->(**) { raise 'callback error' }
      )

      expect { config.trigger(:on_request, method: :get, path: '/test', body: nil) }.not_to raise_error
    end
  end
end
