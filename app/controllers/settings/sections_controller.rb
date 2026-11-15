module Settings
  # /settings. On a phone: the list of sections. On a wide screen: the menu with the display section open,
  # since the server does not know the size of the screen
  class SectionsController < BaseController
    def index
      render "settings/displays/show"
    end

    private

    def sections_list_page?
      true
    end
  end
end
