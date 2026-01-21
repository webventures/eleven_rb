# frozen_string_literal: true

module ElevenRb
  # Manages voice slots to work within ElevenLabs account limits
  #
  # This is the key feature for switching voices in and out of your account
  # when you're limited by your subscription tier.
  #
  # @example Basic usage
  #   manager = client.voice_slots
  #   manager.ensure_available(public_user_id: "abc", voice_id: "xyz", name: "Spanish Voice")
  #
  # @example Check status
  #   status = client.voice_slots.status
  #   puts "#{status[:used]}/#{status[:limit]} slots used"
  class VoiceSlotManager
    attr_reader :client

    # Initialize the manager
    #
    # @param client [Client] the ElevenRb client
    def initialize(client)
      @client = client
      @usage_tracker = {} # voice_id => last_used_at
    end

    # Ensure a voice from the library is available in your account
    #
    # This will:
    # 1. Check if the voice is already in your account
    # 2. If not, check if there's room for a new voice
    # 3. If no room, remove the least recently used voice
    # 4. Add the voice from the library
    #
    # @param public_user_id [String] the public user ID of the voice owner
    # @param voice_id [String] the voice ID
    # @param name [String] the name to give the voice
    # @return [Objects::Voice] the voice (existing or newly added)
    def ensure_available(public_user_id:, voice_id:, name:)
      # Check if already in account
      existing = find_in_account(voice_id)
      if existing
        track_usage(existing.voice_id)
        return existing
      end

      # Make room if needed
      make_room_if_needed!

      # Add from library
      voice = client.voice_library.add(
        public_user_id: public_user_id,
        voice_id: voice_id,
        name: name
      )

      track_usage(voice.voice_id)
      voice
    end

    # Get current slot status
    #
    # @return [Hash] status with :used, :limit, :available, :full keys
    def status
      subscription = client.user.subscription
      voice_count = current_count

      {
        used: voice_count,
        limit: subscription.voice_limit,
        available: (subscription.voice_limit || 0) - voice_count,
        full: subscription.voice_limit ? voice_count >= subscription.voice_limit : false
      }
    end

    # Get current voice count
    #
    # @return [Integer]
    def current_count
      client.voices.list.size
    end

    # Get available slot count
    #
    # @return [Integer]
    def available_slots
      status[:available]
    end

    # Check if slots are full
    #
    # @return [Boolean]
    def full?
      status[:full]
    end

    # Track that a voice was used
    #
    # @param voice_id [String]
    # @return [Time] the tracked time
    def track_usage(voice_id)
      @usage_tracker[voice_id] = Time.now
    end

    # Get voices sorted by last usage (least recent first)
    #
    # @return [Array<Objects::Voice>]
    def voices_by_usage
      voices = client.voices.list
      voices.sort_by { |v| @usage_tracker[v.voice_id] || Time.at(0) }
    end

    # Get the least recently used voice
    #
    # @return [Objects::Voice, nil]
    def least_recently_used
      voices_by_usage.first
    end

    # Remove the least recently used voice
    #
    # @return [Objects::Voice] the removed voice
    # @raise [Errors::VoiceSlotLimitError] if no voices to remove
    def remove_lru!
      lru_voice = least_recently_used
      raise Errors::VoiceSlotLimitError, "No voices available to remove" unless lru_voice

      client.voices.destroy(lru_voice.voice_id)
      @usage_tracker.delete(lru_voice.voice_id)
      lru_voice
    end

    # Remove a specific voice
    #
    # @param voice_id [String]
    # @return [Boolean]
    def remove(voice_id)
      result = client.voices.destroy(voice_id)
      @usage_tracker.delete(voice_id) if result
      result
    end

    # Clear usage tracking data
    #
    # @return [void]
    def reset_tracking!
      @usage_tracker.clear
    end

    # Check if a voice is in the account
    #
    # @param voice_id [String]
    # @return [Boolean]
    def in_account?(voice_id)
      client.voices.list.include_voice?(voice_id)
    end

    # Find a voice in the account by ID
    #
    # @param voice_id [String]
    # @return [Objects::Voice, nil]
    def find_in_account(voice_id)
      client.voices.list.find_by_id(voice_id)
    end

    # Prepare multiple voices at once
    #
    # @param voices [Array<Hash>] array of voice params (public_user_id, voice_id, name)
    # @return [Array<Objects::Voice>]
    def prepare_voices(voices)
      voices.map do |params|
        ensure_available(**params)
      end
    end

    private

    def make_room_if_needed!
      return unless full?

      remove_lru!
    end
  end
end
