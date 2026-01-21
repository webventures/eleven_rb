# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
