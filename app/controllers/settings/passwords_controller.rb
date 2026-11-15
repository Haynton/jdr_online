module Settings
  # Changes the password, confirmed by the current one (Devise's update_with_password).
  # On an error, the security section shows again with its fields in red
  class PasswordsController < SecuritiesController
    def update
      # A copy from the database, not current_user, as in EmailsController
      @user = User.find(current_user.id)
      return show_section_with_errors unless change_password

      # Devise signs the user out when the password changes: this keeps them signed in
      bypass_sign_in(@user)
      redirect_to settings_security_path, notice: t(".updated")
    end

    private

    # Devise reads an empty new password as "keep the current one" and would report a success
    def change_password
      return @user.update_with_password(password_params) if password_params[:password].present?

      @user.errors.add(:password, :blank)
      false
    end

    def show_section_with_errors
      @user.clean_up_passwords
      render "settings/securities/show", status: :unprocessable_content
    end

    def password_params
      params.expect(user: %i[current_password password password_confirmation])
    end
  end
end
