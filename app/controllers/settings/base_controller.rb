module Settings
  # Parent of the settings pages: their layout, and whether the page is the list of sections
  # (on a phone, /settings only shows that list; a section page only shows its section)
  class BaseController < ApplicationController
    layout "settings"
    helper_method :sections_list_page?

    private

    def sections_list_page?
      false
    end
  end
end
