# frozen_string_literal: true

module ElevenRb
  # Provides ActiveSupport::Notifications integration for Rails apps
  #
  # @example Subscribing to events
  #   ActiveSupport::Notifications.subscribe(/eleven_rb/) do |name, start, finish, id, payload|
  #     duration = (finish - start) * 1000
  #     Rails.logger.info("[ElevenRb] #{name} completed in #{duration.round(2)}ms")
  #   end
  module Instrumentation
    module_function

    # Instrument a block with ActiveSupport::Notifications if available
    #
    # @param name [String] the event name (will be suffixed with .eleven_rb)
    # @param payload [Hash] additional data to include in the notification
    # @yield the block to instrument
    # @return [Object] the return value of the block
    def instrument(name, payload = {}, &block)
      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications.instrument("#{name}.eleven_rb", payload, &block)
      elsif block_given?
        yield
      end
    end

    # Check if ActiveSupport::Notifications is available
    #
    # @return [Boolean]
    def available?
      defined?(ActiveSupport::Notifications)
    end
  end
end
