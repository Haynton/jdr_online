module Settings
  # Security section of the settings: password change
  class SecuritiesController < BaseController
    before_action :set_minimum_password_length

    def show
      @user = current_user
    end

    private

    # Shown in the hint of the new password field, like on Devise's pages
    def set_minimum_password_length
      @minimum_password_length = User.password_length.min
    end
  end
end
