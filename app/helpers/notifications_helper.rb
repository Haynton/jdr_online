# The bell of the navigation and its window (shared/_notifications_bell, shared/_notifications_dialog):
# what waits for an answer from the user (Notification)
module NotificationsHelper
  FRAME = "notifications".freeze

  # Counted once per page, for the dot of the bell
  def notifications_count
    @notifications_count ||= Notification.count_for(current_user)
  end

  # The bell loads the notifications into the window. No prefetch: its answer, laid out for the window,
  # would be reused for the same address opened as a page
  def notifications_link_data
    { turbo_frame: FRAME, turbo_prefetch: false }
  end

  # The bell, shaped like the links of the side navigation. With something waiting, the number shows on the icon;
  # screen readers and the tooltip get it in words instead ("1 notification waiting")
  def notifications_bell_link
    label = t("shared.notifications_bell.label")
    return side_nav_link_to(label, notifications_path, icon: "bell", data: notifications_link_data) if nothing_waiting?

    waiting = t("shared.notifications_bell.waiting", count: notifications_count)
    link_to notifications_path, class: NavigationHelper::SIDE_NAV_LINK_CLASSES, title: "#{label} (#{waiting})",
                                aria: current_page_aria(current_page?(notifications_path)),
                                data: notifications_link_data do
      tag.span(nav_icon("bell") + side_nav_count(notifications_count), class: "relative flex") +
        tag.span(label, class: NavigationHelper::SIDE_NAV_LABEL_CLASSES) + tag.span(", #{waiting}", class: "sr-only")
    end
  end

  def nothing_waiting?
    notifications_count.zero?
  end

  def notifications_in_dialog?
    turbo_frame_request_id == FRAME
  end

  # "Luara wants to be your friend": the username in bold, escaped (tag.strong), in a sentence of the locale files
  def notification_text(key, username:, **interpolations)
    t(key, username: tag.strong(username, class: "font-semibold"), **interpolations)
  end
end
