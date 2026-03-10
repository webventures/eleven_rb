# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-10

### Added

- Text-to-Dialogue multi-speaker audio generation via `client.text_to_dialogue.generate` (`POST /v1/text-to-dialogue`)
- `Client#text_to_dialogue` resource with `dialogue` alias
- Multi-speaker input validation (max 10 unique voices, 5000 character limit)
- `eleven_v3` model added to `CostInfo::COST_PER_1K_CHARS` ($0.30/1K chars)
- `Models#latest` method returning the most capable model (`eleven_v3`)
- Audio tags support via v3 model (`[laughs]`, `[whispers]`, `[excited]`, etc.)
- `CostInfo` now accepts `character_count:` keyword as alternative to `text:`
- TTS generation with word-level timestamps via `client.tts.generate_with_timestamps`

### Changed

- `CostInfo#initialize` signature: `text:` is now optional when `character_count:` is provided (backwards-compatible)

## [0.4.0] - 2026-03-10

### Added

- Speech-to-Speech voice conversion via `client.sts.convert` (`POST /v1/speech-to-speech/{voice_id}`)
- `Client#speech_to_speech` resource with `sts` alias
- Accepts file paths (String) or IO objects (IO, StringIO, Tempfile) for audio input
- Multipart upload with binary response support
- Default model: `eleven_english_sts_v2`

### Changed

- `Resources::Base#post_multipart` and `HTTP::Client#post_multipart` now accept `response_type:` parameter (defaults to `:json`, backwards-compatible)

## [0.3.0] - 2026-02-08

### Added

- Music generation via `client.music.generate` (`POST /v1/music`)
- Music streaming via `client.music.stream` (`POST /v1/music/stream`)
- Composition plan creation via `client.music.create_plan` (`POST /v1/music/plan`)
- `Client#generate_music` convenience method

## [0.2.0] - 2026-02-07

### Added

- Sound effects generation via `client.sound_effects.generate` (`POST /v1/sound-generation`)
- `ElevenRb::Error` top-level alias for `ElevenRb::Errors::Base`
- `Client#configured?` and `Configuration#configured?` predicate methods

### Changed

- API key validation deferred to first API call (lazy configuration) — `Client.new` no longer raises without a key

## [0.1.0] - 2026-01-21

### Added

- Initial release
- Text-to-Speech generation with `client.tts.generate`
- Streaming TTS with `client.tts.stream`
- Voice management (list, get, create, update, delete)
- Voice Library access (search, add shared voices)
- Voice Slot Manager for automatic slot management
- Models resource for listing available TTS models
- User/subscription information
- Comprehensive callback system:
  - `on_request` - before each API call
  - `on_response` - after successful response
  - `on_error` - when errors occur
  - `on_audio_generated` - after TTS generation (includes cost info)
  - `on_retry` - before retry attempts
  - `on_rate_limit` - when rate limited
  - `on_voice_added` / `on_voice_deleted` - voice changes
- Automatic retry with exponential backoff
- Structured response objects
- TTSAdapter for future wrapper gem compatibility
- ActiveSupport::Notifications integration (optional)
