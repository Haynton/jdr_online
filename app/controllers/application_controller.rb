class ApplicationController < ActionController::Base
  include Locale

  before_action :authenticate_user!
  layout :layout_for_page
  # The account menu marks "Settings" as the current page with it, error pages included (their URL is /users)
  helper_method :settings_page?

  private

  # Where Devise sends a signed in user: after signing in or up (unless a page asked for before comes first)
  # and after updating the account. "My tables" instead of the home page, which only redirects there
  def signed_in_root_path(_resource_or_scope)
    tables_path
  end

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

  # The settings sections, and the old account page until the account section exists
  def settings_page?
    controller_path.start_with?("settings/") || account_page?
  end
end
