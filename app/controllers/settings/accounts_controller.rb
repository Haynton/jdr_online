module Settings
  # Account section of the settings: email address, log out, account deletion
  class AccountsController < BaseController
    def show
      @user = current_user
    end
  end
end
