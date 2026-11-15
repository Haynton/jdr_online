module Settings
  # Changes the email address, confirmed by the current password (Devise's update_with_password).
  # On an error, the account section shows again with its fields in red
  class EmailsController < BaseController
    def update
      # A copy from the database, not current_user: with a wrong password, Devise still puts the refused
      # email on the object, and the rest of the page would see it as the saved one
      @user_for_email = User.find(current_user.id)
      if @user_for_email.update_with_password(email_params)
        return redirect_to(settings_account_path, notice: t(".updated"))
      end

      @user_for_email.clean_up_passwords
      @user_for_username = current_user
      render "settings/accounts/show", status: :unprocessable_content
    end

    private

    def email_params
      params.expect(user: %i[email current_password])
    end
  end
end
