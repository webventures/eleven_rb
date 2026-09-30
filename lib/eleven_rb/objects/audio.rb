# frozen_string_literal: true

require 'stringio'

module ElevenRb
  module Objects
    # Represents generated audio data
    class Audio
      attr_reader :data, :format, :voice_id, :text, :model_id,
                  :request_id, :character_cost, :dropped_settings

      # Initialize audio object
      #
      # @param data [String] binary audio data
      # @param format [String] audio format (e.g., "mp3_44100_128")
      # @param voice_id [String] the voice ID used
      # @param text [String] the text that was converted
      # @param model_id [String, nil] the model ID used
      # @param request_id [String, nil] the API's `request-id` response header (usable as
      #   previous_request_ids / next_request_ids on a later request)
      # @param character_cost [Integer, nil] the API's `character-cost` response header
      # @param dropped_settings [Array<Symbol>] voice settings the gem dropped because the model ignores them
      def initialize(data:, format:, voice_id:, text:, model_id: nil, request_id: nil, character_cost: nil,
                     dropped_settings: [])
        @data = data
        @format = format
        @voice_id = voice_id
        @text = text
        @model_id = model_id
        @request_id = request_id
        @character_cost = character_cost
        @dropped_settings = Array(dropped_settings).dup.freeze
      end

      # Save audio to a file
      #
      # @param path [String] file path to save to
      # @return [String] the path that was written to
      def save_to_file(path)
        File.binwrite(path, data)
        path
      end

      # Get the size in bytes
      #
      # @return [Integer]
      def bytes
        data.bytesize
      end

      # Get the size in kilobytes
      #
      # @return [Float]
      def kilobytes
        bytes / 1024.0
      end

      # Convert to IO object for streaming/uploading
      #
      # @return [StringIO]
      def to_io
        StringIO.new(data)
      end

      # Get the content type based on format
      #
      # @return [String]
      def content_type
        case format
        when /mp3/
          'audio/mpeg'
        when /pcm/
          'audio/pcm'
        when /ogg|opus/
          'audio/ogg'
        when /wav/
          'audio/wav'
        when /flac/
          'audio/flac'
        else
          'application/octet-stream'
        end
      end

      # Get file extension based on format
      #
      # @return [String]
      def extension
        case format
        when /mp3/
          'mp3'
        when /pcm/
          'pcm'
        when /ogg|opus/
          'ogg'
        when /wav/
          'wav'
        when /flac/
          'flac'
        else
          'bin'
        end
      end

      # Get character count of source text
      #
      # @return [Integer]
      def character_count
        text.length
      end

      # Check if data is present
      #
      # @return [Boolean]
      def present?
        data && !data.empty?
      end

      # Inspect the object
      #
      # @return [String]
      def inspect
        "#<#{self.class.name} format=#{format.inspect} bytes=#{bytes} voice_id=#{voice_id.inspect}>"
      end
    end
  end
end
