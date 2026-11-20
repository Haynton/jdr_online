module Settings
  # Parent of the settings pages: their layout, and whether the page is the list of sections
  # (on a phone, /settings only shows that list; a section page only shows its section)
  class BaseController < ApplicationController
    layout "settings"
    helper_method :sections_list_page?
    before_action :vary_on_turbo_frame

    private

    def sections_list_page?
      false
    end

    # The same address answers laid out as a page or for the settings window (SettingsDialogHelper),
    # depending on the Turbo-Frame header: no cache may hand one for the other
    def vary_on_turbo_frame
      response.headers["Vary"] = [response.headers["Vary"], "Turbo-Frame"].compact.join(", ")
    end
  end
end
