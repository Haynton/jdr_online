module Settings
  # The picture of the account, in Settings › Account (HasAvatar): sent framed by the page, or removed (its initials
  # come back). Refused, the account section shows again with the reason under the picker
  class AvatarsController < BaseController
    # The section shows the new picture: the message is for screen readers only
    def update
      # A copy from the database, not current_user: on a refusal, the navigation keeps showing the saved picture
      user = User.find(current_user.id)
      if user.change_avatar(params.dig(:user, :avatar))
        return redirect_to(settings_account_path, flash: { screen_reader_notice: t(".updated") })
      end

      @avatar_error = user.errors.messages_for(:avatar).first
      @user_for_username = current_user
      @user_for_email = current_user
      render "settings/accounts/show", status: :unprocessable_content
    end

    def destroy
      current_user.remove_avatar
      redirect_to settings_account_path, flash: { screen_reader_notice: t(".removed") }
    end
  end
end
