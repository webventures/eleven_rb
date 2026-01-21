# frozen_string_literal: true

module ElevenRb
  module Objects
    # Represents user account information
    class UserInfo < Base
      attribute :user_id
      attribute :email
      attribute :first_name
      attribute :is_new_user, type: :boolean
      attribute :xi_api_key
      attribute :can_use_delayed_payment_methods, type: :boolean
      attribute :is_onboarding_completed, type: :boolean
      attribute :is_onboarding_checklist_completed, type: :boolean

      # Get full display name
      #
      # @return [String]
      def display_name
        first_name || email&.split("@")&.first || "User"
      end
    end
  end
end
