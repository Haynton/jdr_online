module Settings
  # Account section of the settings: username, email address, log out, account deletion.
  # One user object per form: an error in one form must not show in the other
  class AccountsController < BaseController
    def show
      @user_for_username = current_user
      @user_for_email = current_user
    end
  end
end
