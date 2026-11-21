module PageBackgroundsHelper
  # The pages under a large cover (home, "My tables") ask for the deeper night of the dark theme (page-deep):
  # the plain gray of the other pages (page) washed out their landscape
  def use_deep_page_background
    content_for :page_background, "bg-page-deep"
  end

  def page_background_class
    content_for(:page_background).presence || "bg-page"
  end
end
