# frozen_string_literal: true

module ElevenRb
  # What each ElevenLabs model family accepts, keyed by model-id family.
  #
  # The API silently ignores voice settings a model does not honour (Eleven v4
  # accepts `speed`, `style` and `use_speaker_boost` and does nothing with them),
  # so the gem uses this table to send only the settings that take effect, to
  # cap text length per model, and to answer feature questions (audio tags,
  # SSML `<break>` tags, request continuity via previous_text / next_text).
  #
  # @example
  #   ElevenRb::ModelCapabilities.supported_voice_settings('eleven_v4')
  #   # => [:stability, :similarity_boost]
  #   ElevenRb::ModelCapabilities.max_text_length('eleven_flash_v2_5') # => 40_000
  #   ElevenRb::ModelCapabilities.supports?('eleven_v4', :audio_tags)  # => true
  module ModelCapabilities
    # Capability record for one model family
    Capabilities = Struct.new(:voice_settings, :max_text_length, :ssml_break, :audio_tags, :continuity,
                              keyword_init: true) do
      def ssml_break? = ssml_break
      def audio_tags? = audio_tags
      def continuity? = continuity
    end

    ALL_VOICE_SETTINGS = %i[stability similarity_boost style use_speaker_boost speed].freeze

    def self.build(voice_settings:, max_text_length:, ssml_break:, audio_tags:, continuity:)
      Capabilities.new(
        voice_settings: voice_settings.freeze,
        max_text_length: max_text_length,
        ssml_break: ssml_break,
        audio_tags: audio_tags,
        continuity: continuity
      ).freeze
    end
    private_class_method :build

    V4 = build(voice_settings: %i[stability similarity_boost], max_text_length: 10_000,
               ssml_break: false, audio_tags: true, continuity: true)
    V3_CONVERSATIONAL = build(voice_settings: %i[stability similarity_boost use_speaker_boost], max_text_length: 5_000,
                              ssml_break: false, audio_tags: true, continuity: true)
    V3 = build(voice_settings: %i[stability similarity_boost], max_text_length: 5_000,
               ssml_break: false, audio_tags: true, continuity: true)
    V2_5_FAST = build(voice_settings: ALL_VOICE_SETTINGS, max_text_length: 40_000,
                      ssml_break: true, audio_tags: false, continuity: true)
    V2_FAST = build(voice_settings: ALL_VOICE_SETTINGS, max_text_length: 30_000,
                    ssml_break: true, audio_tags: false, continuity: true)
    DEFAULT = build(voice_settings: ALL_VOICE_SETTINGS, max_text_length: 10_000,
                    ssml_break: true, audio_tags: false, continuity: true)

    # Ordered [matcher, capabilities] pairs; the first match wins.
    FAMILIES = [
      [/\Aeleven_v4/, V4],
      [/\Aeleven_v3_conversational/, V3_CONVERSATIONAL],
      [/\Aeleven_v3/, V3],
      [/\Aeleven_(flash|turbo)_v2_5/, V2_5_FAST],
      [/\Aeleven_(flash|turbo)_v2/, V2_FAST]
    ].freeze

    FEATURES = %i[audio_tags ssml_break continuity].freeze

    module_function

    # Capabilities for a model id (unknown ids get the permissive default)
    #
    # @param model_id [String, Symbol, nil]
    # @return [Capabilities] frozen
    def for(model_id)
      id = model_id.to_s
      FAMILIES.each { |matcher, caps| return caps if matcher.match?(id) }
      DEFAULT
    end

    # Voice settings keys the model honours
    #
    # @param model_id [String]
    # @return [Array<Symbol>]
    def supported_voice_settings(model_id)
      self.for(model_id).voice_settings
    end

    # Maximum characters per request for the model
    #
    # @param model_id [String]
    # @return [Integer]
    def max_text_length(model_id)
      self.for(model_id).max_text_length
    end

    # Whether the model supports a feature
    #
    # @param model_id [String]
    # @param feature [Symbol] :audio_tags, :ssml_break or :continuity
    # @return [Boolean]
    def supports?(model_id, feature)
      feature = feature.to_sym
      raise ArgumentError, "Unknown feature #{feature.inspect} (expected one of #{FEATURES.join(', ')})" unless FEATURES.include?(feature)

      self.for(model_id).public_send(feature) ? true : false
    end
  end
end
