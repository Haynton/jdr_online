class ApplicationController < ActionController::Base
  include Locale

  before_action :authenticate_user!
  layout :layout_for_page
  # The account menu marks "Settings" as the current page with it
  helper_method :settings_page?

  private

  # Where Devise sends a signed in user: after signing in or up (unless a page asked for before comes first)
  # and after updating the account. "My tables" instead of the home page, which only redirects there
  def signed_in_root_path(_resource_or_scope)
    game_tables_path
  end

  # The pages of Devise (sign in, sign up, passwords) are visitor pages: they get the auth layout.
  # The account itself is managed in the settings
  def layout_for_page
    devise_controller? ? "auth" : "application"
  end

  def settings_page?
    controller_path.start_with?("settings/")
  end
end
