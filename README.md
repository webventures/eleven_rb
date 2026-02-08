# ElevenRb

[![Gem Version](https://badge.fury.io/rb/eleven_rb.svg)](https://badge.fury.io/rb/eleven_rb)
[![CI](https://github.com/webventures/eleven_rb/actions/workflows/ci.yml/badge.svg)](https://github.com/webventures/eleven_rb/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Ruby client for the [ElevenLabs](https://try.elevenlabs.io/qyk2j8gumrjz) Text-to-Speech, Sound Effects, and Music API.

## Features

- Text-to-Speech generation and streaming
- Sound effects generation from text descriptions
- Music generation from prompts or composition plans
- Voice management (list, get, create, update, delete)
- Voice Library access (search 10,000+ community voices)
- Voice Slot Manager for automatic slot management within account limits
- Comprehensive callback system for logging, monitoring, and cost tracking
- Automatic retry with configurable backoff
- Structured response objects
- Future-ready adapter for multi-provider wrapper gems

## Requirements

- Ruby >= 3.0
- An [ElevenLabs API key](https://elevenlabs.io/app/settings/api-keys)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eleven_rb'
```

Or install directly:

```bash
gem install eleven_rb
```

## Quick Start

```ruby
require 'eleven_rb'

# Initialize with API key
client = ElevenRb::Client.new(api_key: "your-api-key")

# Or use environment variable ELEVENLABS_API_KEY
client = ElevenRb::Client.new

# Generate speech
audio = client.tts.generate("Hello world!", voice_id: "JBFqnCBsd6RMkjVDRZzb")
audio.save_to_file("output.mp3")

# List voices
client.voices.list.each do |voice|
  puts "#{voice.name} (#{voice.voice_id})"
end
```

## Usage

### Text-to-Speech

```ruby
# Basic generation
audio = client.tts.generate("Hello world", voice_id: "voice_id")
audio.save_to_file("output.mp3")

# With options
audio = client.tts.generate(
  "Hello world",
  voice_id: "voice_id",
  model_id: "eleven_multilingual_v2",
  voice_settings: {
    stability: 0.5,
    similarity_boost: 0.75
  },
  output_format: "mp3_44100_192"
)

# Streaming
File.open("output.mp3", "wb") do |file|
  client.tts.stream("Long text here...", voice_id: "voice_id") do |chunk|
    file.write(chunk)
  end
end
```

### Sound Effects

```ruby
# Generate a sound effect from a text description
audio = client.sound_effects.generate("thunder rumbling in the distance")
audio.save_to_file("thunder.mp3")

# With options
audio = client.sound_effects.generate(
  "footsteps on gravel",
  duration_seconds: 3.0,
  prompt_influence: 0.5,
  output_format: "mp3_44100_192"
)

# Generate a loopable sound effect
audio = client.sound_effects.generate("gentle rain", loop: true)

# Convenience method
audio = client.generate_sound_effect("explosion")
```

### Music

```ruby
# Generate music from a text prompt
audio = client.music.generate("upbeat jazz piano solo")
audio.save_to_file("jazz.mp3")

# With options (duration, instrumental-only)
audio = client.music.generate(
  "epic orchestral battle theme",
  music_length_ms: 30_000,
  force_instrumental: true
)

# Using a composition plan (create_plan is free, no credits used)
plan = client.music.create_plan("lo-fi hip hop beats", music_length_ms: 60_000)
audio = client.music.generate(composition_plan: plan)
audio.save_to_file("lo-fi.mp3")

# Streaming
File.open("song.mp3", "wb") do |file|
  client.music.stream("ambient electronic") { |chunk| file.write(chunk) }
end

# Convenience method
audio = client.generate_music("chill acoustic guitar")
```

### Voice Management

```ruby
# List all voices
voices = client.voices.list
voices.each { |v| puts v.display_name }

# Get a specific voice
voice = client.voices.find("voice_id")
puts voice.name

# Delete a voice
client.voices.destroy("voice_id")

# Filter voices
spanish_voices = voices.by_language("spanish")
female_voices = voices.by_gender("female")
```

### Voice Library

Search and add voices from ElevenLabs' 10,000+ community voice library:

```ruby
# Search for Spanish female voices
results = client.voice_library.search(
  language: "Spanish",
  gender: "female",
  page_size: 20
)

results.each do |voice|
  puts "#{voice.name} - #{voice.accent}"
end

# Add a voice from the library to your account
voice = client.voice_library.add(
  public_user_id: voice.public_owner_id,
  voice_id: voice.voice_id,
  name: "My Spanish Voice"
)
```

### Voice Slot Management

Automatically manage voice slots when you're limited by your subscription:

```ruby
# Check current slot status
status = client.voice_slots.status
puts "#{status[:used]}/#{status[:limit]} slots used"

# Ensure a voice is available (adds from library if needed, removes LRU if full)
voice = client.voice_slots.ensure_available(
  public_user_id: "owner_id",
  voice_id: "voice_id",
  name: "Spanish Voice"
)

# Now use the voice
audio = client.tts.generate("Hola mundo", voice_id: voice.voice_id)

# Prepare multiple voices for a conversation
voices = client.voice_slots.prepare_voices([
  { public_user_id: "abc", voice_id: "v1", name: "Maria" },
  { public_user_id: "def", voice_id: "v2", name: "Carlos" }
])
```

### Callbacks

Set up callbacks for logging, monitoring, and cost tracking:

```ruby
client = ElevenRb::Client.new(
  api_key: ENV['ELEVENLABS_API_KEY'],

  # Logging
  on_request: ->(method:, path:, body:) {
    Rails.logger.info("[ElevenLabs] #{method.upcase} #{path}")
  },

  on_response: ->(method:, path:, response:, duration:) {
    Rails.logger.info("[ElevenLabs] #{method.upcase} #{path} (#{duration}ms)")
  },

  # Error tracking
  on_error: ->(error:, method:, path:, context:) {
    Sentry.capture_exception(error, extra: { path: path })
  },

  # Cost tracking
  on_audio_generated: ->(audio:, voice_id:, text:, cost_info:) {
    UsageRecord.create!(
      characters: cost_info[:character_count],
      estimated_cost: cost_info[:estimated_cost]
    )
  },

  # Rate limit handling
  on_rate_limit: ->(retry_after:, error:) {
    SlackNotifier.notify("Rate limited, retry in #{retry_after}s")
  }
)
```

### Models

```ruby
# List available models
models = client.models.list
models.each { |m| puts "#{m.name} (#{m.model_id})" }

# Get multilingual models
client.models.multilingual

# Get turbo/fast models
client.models.turbo
```

### User Information

```ruby
# Get subscription info
sub = client.user.subscription
puts "Characters: #{sub.character_count}/#{sub.character_limit}"
puts "Resets at: #{sub.next_reset_at}"

# Get user info
info = client.user.info
puts "Email: #{info.email}"
```

## Configuration

```ruby
client = ElevenRb::Client.new(
  api_key: "your-api-key",
  timeout: 120,              # Request timeout in seconds
  open_timeout: 10,          # Connection timeout
  max_retries: 3,            # Max retry attempts
  retry_delay: 1.0,          # Base delay between retries
  logger: Rails.logger       # Optional logger
)
```

## Error Handling

```ruby
begin
  audio = client.tts.generate("Hello", voice_id: "invalid")
rescue ElevenRb::Errors::NotFoundError => e
  puts "Voice not found: #{e.message}"
rescue ElevenRb::Errors::RateLimitError => e
  puts "Rate limited, retry after #{e.retry_after} seconds"
rescue ElevenRb::Errors::AuthenticationError => e
  puts "Invalid API key"
rescue ElevenRb::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ElevenRb::Errors::APIError => e
  puts "API error: #{e.message} (status: #{e.http_status})"
end

# Or use the top-level alias to catch all ElevenRb errors
begin
  audio = client.tts.generate("Hello", voice_id: "abc123")
rescue ElevenRb::Error => e
  puts "Something went wrong: #{e.message}"
end
```

## Rails Integration

The client can be initialized without an API key and won't raise until the first API call,
making it safe to use in test/CI environments where the key may not be set.

```ruby
# config/initializers/eleven_rb.rb
ElevenRb.configure do |config|
  config.api_key = Rails.application.credentials.dig(:elevenlabs, :api_key)

  config.on_error = ->(error:, **) {
    Sentry.capture_exception(error, tags: { service: "elevenlabs" })
  }

  config.on_audio_generated = ->(cost_info:, **) {
    TtsUsage.create!(cost_info)
  }
end

# Then use anywhere
audio = ElevenRb.client.tts.generate("Hello", voice_id: "abc123")
```

## Voice Slot Limits by Plan

| Plan | Voice Slots |
|------|-------------|
| Free | 3 |
| Starter | 10 |
| Creator | 30 |
| Pro | 160 |
| Scale | 660 |
| Business | 660 |

## References

- [ElevenLabs API Documentation](https://elevenlabs.io/docs/api-reference)
- [ElevenLabs Developer Portal](https://try.elevenlabs.io/qyk2j8gumrjz)
- [Voice Library](https://elevenlabs.io/voice-library)

## Changelog

For a detailed list of changes for each version of this project, please see the [CHANGELOG](CHANGELOG.md).

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bundle exec rake console` for an interactive prompt that will allow you to experiment.

```bash
bundle install          # Install dependencies
bundle exec rspec       # Run tests
bundle exec rubocop     # Run linter
bundle exec rake build  # Build gem
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/webventures/eleven_rb.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
