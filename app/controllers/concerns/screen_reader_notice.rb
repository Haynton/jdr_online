# A notice that only repeats what the page already shows ("Signed in.", "Signed out.", "Welcome!"):
# hidden on screen, still read by screen readers (shared/_flashes shows flash[:screen_reader_notice] as sr-only)
module ScreenReaderNotice
  extend ActiveSupport::Concern

  private

  # Read, then delete: unlike a Hash, flash.delete returns the flash itself, not the message
  def keep_for_screen_readers_only
    flash[:screen_reader_notice] = flash[:notice]
    flash.delete(:notice)
  end
end
