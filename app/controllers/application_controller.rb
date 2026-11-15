class ApplicationController < ActionController::Base
  include Locale

  before_action :authenticate_user!
  layout :layout_for_page
  # The navbar marks "My account" as the current page with it, error pages included (their URL is /users)
  helper_method :account_page?

  private

  # Visitor pages of Devise (sign in, sign up, passwords) get the auth layout,
  # the account page keeps the application one with its navbar
  def layout_for_page
    return "application" unless devise_controller?
    return "application" if account_page?

    "auth"
  end

  def account_page?
    controller_name == "registrations" && action_name.in?(%w[edit update destroy cancel])
  end
end
