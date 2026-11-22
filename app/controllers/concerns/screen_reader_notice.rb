# Devise messages that only repeat what the next page already shows ("Signed in.", "Welcome!", "You are already
# signed in." on the user's tables): hidden on screen, still read by screen readers
# (shared/_flashes shows flash[:screen_reader_notice] as sr-only). Included by the Devise controllers of users/
module ScreenReaderNotice
  extend ActiveSupport::Concern

  SCREEN_READER_ONLY_DEVISE_MESSAGES = %i[
    signed_in signed_out signed_up already_authenticated updated destroyed
  ].freeze

  protected

  # Every Devise message goes through here, set_flash_message! included
  def set_flash_message(key, kind, options = {})
    super
    keep_for_screen_readers_only(key) if kind.to_sym.in?(SCREEN_READER_ONLY_DEVISE_MESSAGES)
  end

  private

  # Read, then delete: unlike a Hash, flash.delete returns the flash itself, not the message
  def keep_for_screen_readers_only(key)
    flash[:screen_reader_notice] = flash[key]
    flash.delete(key)
  end
end
