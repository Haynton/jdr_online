module Settings
  # Changes the username, without the current password: it is only a name shown to the other players.
  # On an error, the account section shows again with the username field in red
  class UsernamesController < BaseController
    def update
      # A copy from the database, not current_user: the navbar keeps showing the saved username
      @user_for_username = User.find(current_user.id)
      return redirect_to(settings_account_path, notice: t(".updated")) if @user_for_username.update(username_params)

      @user_for_email = current_user
      render "settings/accounts/show", status: :unprocessable_content
    end

    private

    def username_params
      params.expect(user: [:username])
    end
  end
end
