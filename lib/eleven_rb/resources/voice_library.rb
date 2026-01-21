# frozen_string_literal: true

module ElevenRb
  module Resources
    # Voice library resource for accessing shared voices
    #
    # @example Search for Spanish voices
    #   voices = client.voice_library.search(language: "Spanish", gender: "female")
    #
    # @example Add a voice from the library
    #   voice = client.voice_library.add(
    #     public_user_id: "abc123",
    #     voice_id: "xyz789",
    #     name: "My Spanish Voice"
    #   )
    class VoiceLibrary < Base
      CATEGORIES = %w[professional famous high_quality].freeze
      MAX_PAGE_SIZE = 100

      # Search the shared voice library
      #
      # @param page_size [Integer] results per page (max 100)
      # @param category [String] voice category filter
      # @param gender [String] gender filter
      # @param age [String] age filter
      # @param accent [String] accent filter
      # @param language [String] language filter
      # @param locale [String] locale filter
      # @param search [String] search term
      # @param use_cases [Array<String>] use case filters
      # @param featured [Boolean] only featured voices
      # @param reader_app_enabled [Boolean] only reader app enabled
      # @param owner_id [String] filter by owner
      # @param sort [String] sort order
      # @param page [String] pagination cursor
      # @return [Collections::LibraryVoiceCollection]
      def search(
        page_size: 30,
        category: nil,
        gender: nil,
        age: nil,
        accent: nil,
        language: nil,
        locale: nil,
        search: nil,
        use_cases: nil,
        featured: nil,
        reader_app_enabled: nil,
        owner_id: nil,
        sort: nil,
        page: nil
      )
        params = {
          page_size: [page_size.to_i, MAX_PAGE_SIZE].min,
          category: category,
          gender: gender,
          age: age,
          accent: accent,
          language: language,
          locale: locale,
          search: search,
          use_cases: use_cases&.join(","),
          featured: featured,
          reader_app_enabled: reader_app_enabled,
          owner_id: owner_id,
          sort: sort,
          cursor: page
        }.compact

        response = get("/shared-voices", params)
        Collections::LibraryVoiceCollection.from_response(response)
      end

      # Add a shared voice to your account
      #
      # @param public_user_id [String] the public user ID of the voice owner
      # @param voice_id [String] the voice ID
      # @param name [String] the name to give the voice in your account
      # @return [Objects::Voice]
      def add(public_user_id:, voice_id:, name:)
        validate_presence!(public_user_id, "public_user_id")
        validate_presence!(voice_id, "voice_id")
        validate_presence!(name, "name")

        response = post("/voices/add/#{public_user_id}/#{voice_id}", { new_name: name })

        # Trigger callback
        http_client.config.trigger(:on_voice_added, voice_id: response["voice_id"], name: name)

        # Return a Voice object with the info we have
        Objects::Voice.from_response({
          "voice_id" => response["voice_id"],
          "name" => name
        })
      end

      # Search for voices by keyword
      #
      # @param query [String] search query
      # @param options [Hash] additional search options
      # @return [Collections::LibraryVoiceCollection]
      def find(query, **options)
        search(search: query, **options)
      end

      # Get all Spanish voices
      #
      # @param options [Hash] additional search options
      # @return [Collections::LibraryVoiceCollection]
      def spanish(**options)
        search(language: "Spanish", **options)
      end

      # Get all professional voices
      #
      # @param options [Hash] additional search options
      # @return [Collections::LibraryVoiceCollection]
      def professional(**options)
        search(category: "professional", **options)
      end

      # Iterate through all pages of results
      #
      # @param options [Hash] search options
      # @yield [Collections::LibraryVoiceCollection] each page of results
      # @return [Enumerator] if no block given
      def each_page(**options, &block)
        return enum_for(:each_page, **options) unless block_given?

        cursor = nil
        loop do
          collection = search(**options, page: cursor)
          yield collection

          break unless collection.has_more?

          cursor = collection.next_cursor
        end
      end

      # Get all voices matching criteria (auto-paginates)
      #
      # @param max_pages [Integer] maximum pages to fetch (safety limit)
      # @param options [Hash] search options
      # @return [Array<Objects::LibraryVoice>]
      def all(max_pages: 10, **options)
        voices = []
        pages = 0

        each_page(**options) do |collection|
          voices.concat(collection.to_a)
          pages += 1
          break if pages >= max_pages
        end

        voices
      end
    end
  end
end
