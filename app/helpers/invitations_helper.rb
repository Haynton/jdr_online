module InvitationsHelper
  # The invitation page is as tall as the screen, like the home page and "My tables": under the top bar of the
  # visitors (4rem), or beside the navigation of a signed in user (above the floating bar of a phone, 5rem)
  def invitation_page_height_classes
    user_signed_in? ? "min-h-[calc(100dvh-5rem)] md:min-h-dvh" : "min-h-[calc(100dvh-4rem)]"
  end
end
