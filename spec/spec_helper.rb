# frozen_string_literal: true

require 'bundler/setup'
require 'eleven_rb'
require 'vcr'
require 'webmock/rspec'

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV.fetch('ELEVENLABS_API_KEY', nil) }
  config.filter_sensitive_data('<API_KEY>') do |interaction|
    interaction.request.headers['Xi-Api-Key']&.first
  end

  # Allow WebMock stubs to work when no cassette is in use
  config.allow_http_connections_when_no_cassette = true

  # Default cassette options
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed

  # Helper to create a test client
  config.before(:each) do
    ElevenRb.reset!
  end
end

# Shared test helpers
module TestHelpers
  def test_client(api_key: 'test-api-key', **options)
    ElevenRb::Client.new(api_key: api_key, **options)
  end

  def stub_elevenlabs_request(method, path, response_body: {}, status: 200, query: nil)
    url = "https://api.elevenlabs.io/v1#{path}"
    stub = stub_request(method, url)
    stub = stub.with(query: query) if query
    stub.to_return(
      status: status,
      body: response_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def stub_elevenlabs_binary_request(method, path, response_body: '', status: 200, query: nil)
    url = "https://api.elevenlabs.io/v1#{path}"
    stub = stub_request(method, url)
    stub = stub.with(query: query) if query
    stub.to_return(
      status: status,
      body: response_body,
      headers: { 'Content-Type' => 'audio/mpeg' }
    )
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
