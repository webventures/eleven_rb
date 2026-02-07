# frozen_string_literal: true

RSpec.describe ElevenRb::Error do
  it 'is an alias for ElevenRb::Errors::Base' do
    expect(described_class).to eq(ElevenRb::Errors::Base)
  end

  it 'catches subclass errors' do
    expect do
      raise ElevenRb::Errors::ValidationError, 'test'
    end.to raise_error(ElevenRb::Error)
  end

  it 'catches ConfigurationError' do
    expect do
      raise ElevenRb::Errors::ConfigurationError, 'test'
    end.to raise_error(ElevenRb::Error)
  end
end
