# frozen_string_literal: true

module ElevenRb
  module Errors
    # Base error class for all ElevenRb errors
    class Base < StandardError
      attr_reader :http_status, :response_body, :error_code

      def initialize(message = nil, http_status: nil, response_body: nil, error_code: nil)
        @http_status = http_status
        @response_body = response_body
        @error_code = error_code
        super(message)
      end
    end

    # Configuration/setup errors
    class ConfigurationError < Base; end

    # HTTP 400 - Bad request / validation errors
    class ValidationError < Base; end

    # HTTP 401 - Unauthorized
    class AuthenticationError < Base; end

    # HTTP 403 - Forbidden
    class ForbiddenError < Base; end

    # HTTP 404 - Not found
    class NotFoundError < Base; end

    # HTTP 422 - Unprocessable entity
    class UnprocessableError < Base; end

    # HTTP 429 - Rate limited
    class RateLimitError < Base
      attr_reader :retry_after

      def initialize(message = nil, retry_after: nil, **kwargs)
        @retry_after = retry_after
        super(message, **kwargs)
      end
    end

    # HTTP 5xx - Server errors
    class ServerError < Base; end

    # Generic API error (fallback)
    class APIError < Base; end

    # Voice slot specific errors
    class VoiceSlotLimitError < Base; end

    # Network/connection errors
    class ConnectionError < Base; end
    class TimeoutError < ConnectionError; end
  end
end
