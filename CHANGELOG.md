# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-09-30

### Added

- Eleven v4 support (`eleven_v4`, `eleven_v4_turbo`) across Text-to-Speech and Text-to-Dialogue
- `ElevenRb::ModelCapabilities` — per model-family table of honoured voice settings, max text length, SSML `<break>` support, audio-tag support and continuity support (`for`, `supported_voice_settings`, `max_text_length`, `supports?`)
- `Objects::VoiceSettings.for_model(model_id, overrides)` → `[settings, dropped_keys]`, building only the settings a model honours
- `Configuration#strict_voice_settings` (default `false`): raise `ValidationError` instead of warning when a voice setting the model ignores is passed
- Optional TTS keywords on `generate`, `stream` and `generate_with_timestamps` (omitted from the body when nil): `language_code`, `apply_text_normalization`, `seed`, `previous_text`, `next_text`, `previous_request_ids`, `next_request_ids`, `pronunciation_dictionary_locators`, `use_pvc_as_ivc`
- Response metadata: `Objects::Audio#request_id`, `#character_cost` (from the `request-id` / `character-cost` headers) and `#dropped_settings`; `on_audio_generated` also receives `request_id:` (nil for streams)
- `TextToSpeech#generate_with_timestamps` now also returns `normalized_alignment`, `request_id` and `character_cost`
- `TextToDialogue#generate_with_timestamps` (`POST /v1/text-to-dialogue/with-timestamps`) returning `audio`, `alignment`, `normalized_alignment`, `voice_segments` and `request_id`
- Text-to-Dialogue keywords `use_pvc_as_ivc`, `previous_text`, `future_text`, `previous_request_ids`, `next_request_ids`, `pronunciation_dictionary_locators`; a logger warning above `RECOMMENDED_MAX_TEXT_LENGTH` (2,000 characters)
- `HTTP::Client#post(..., with_meta: true)` returning `{ body:, headers: }`, and `Resources::Base#post_with_meta` / `#post_binary_with_meta`
- `Models#find(model_id)`
- `Objects::Model#model_rates`, `#maximum_text_length_per_request`, `#requires_alpha_access`, `#supported_voice_settings`
- `CostInfo::COST_PER_1K_CHARS` entries for `eleven_v4` ($0.30), `eleven_v4_turbo` ($0.15) and `eleven_v3_conversational` ($0.15)
- `opus_*` output formats map to the `ogg` extension and `audio/ogg` content type

### Changed

- Voice settings are filtered per model: known keys a model ignores (`stability`, `similarity_boost`, `style`, `use_speaker_boost`, `speed` minus the model's supported set) are dropped from the request (logged, and listed on `audio.dropped_settings`); unknown voice-setting keys pass through untouched on every model, so a new API field is never swallowed. `eleven_v3` / `eleven_v4` now send only `stability` and `similarity_boost` by default; `eleven_multilingual_v2` requests are byte-identical to 1.0.0. Override keys are symbolized and nil values removed (a nil override is never reported as dropped)
- Text length is capped per model (`ModelCapabilities.max_text_length`): 5,000 for `eleven_v3`, 10,000 for `eleven_v4` and `eleven_multilingual_v2`, 30,000 / 40,000 for the flash and turbo models. `TextToSpeech::MAX_TEXT_LENGTH` stays defined but is no longer the cap
- `TextToDialogue::DEFAULT_MODEL` is now `eleven_v4`
- Text-to-Dialogue's hard text cap now follows the model (10,000 characters on `eleven_v4`, 5,000 on `eleven_v3`) instead of a flat 5,000; `TextToDialogue::MAX_TEXT_LENGTH` stays defined but is no longer the cap
- `Models#latest` returns `eleven_v4`, else `eleven_v3`, else the default model
- `TextToSpeech::OUTPUT_FORMATS` refreshed to the current list (documentation only, not validated)
- Callbacks that declare their keywords explicitly (no `**rest`) receive only the keywords they declare, so callbacks written for 1.0.0 keep working as new keywords are added

### Fixed

- `Models#list` (and everything built on it: `get`, `default`, `latest`, `multilingual`, `turbo`, `tts_capable`, `ids`, `TTSAdapter#list_models`) recursed until `SystemStackError`, because `Models#get(model_id)` shadowed `Resources::Base#get`

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
