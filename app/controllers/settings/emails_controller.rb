module Settings
  # Changes the email address, confirmed by the current password (Devise's update_with_password).
  # On an error, the account section shows again with its fields in red
  class EmailsController < BaseController
    def update
      # A copy from the database, not current_user: with a wrong password, Devise still puts the refused
      # email on the object, and the navbar would show it
      @user = User.find(current_user.id)
      return redirect_to(settings_account_path, notice: t(".updated")) if @user.update_with_password(email_params)

      @user.clean_up_passwords
      render "settings/accounts/show", status: :unprocessable_content
    end

    private

    def email_params
      params.expect(user: %i[email current_password])
    end
  end
end
