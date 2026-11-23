module Users
  class PasswordsController < Devise::PasswordsController
    include DeviseLocale
    include ScreenReaderNotice

    # A reset email that cannot leave (the email service refuses or cannot be reached) shows a clear message in the
    # language of the player, in a floating message, instead of a page of error in English. The email typed stays in
    # its field, and the cause goes to the logs
    def create
      super
    rescue *ApplicationMailer::DELIVERY_ERRORS => error
      Rails.logger.error("Reset password email not sent: #{error.class}: #{error.message}")
      self.resource = resource_class.new(email: params.dig(resource_name, :email))
      flash.now[:alert] = t(".email_not_sent")
      render :new, status: :service_unavailable
    end
  end
end
