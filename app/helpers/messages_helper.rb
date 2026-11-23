module MessagesHelper
  # The tinted background and pale *-line border alone barely show (1.04 to 2.02 against the page):
  # a 1 px border in the text color at 70 % reaches 3.32 to 7.24, softer than the full color
  MESSAGE_BASE_CLASSES = "flex items-start gap-2 rounded-lg border px-3.5 py-3 text-[13px]".freeze

  # icon: the partial written in full, so that a search for its file name finds it
  # toast_icon: the small round icon of a floating message, its only color (on the surface of the theme)
  # toast_duration: how long a floating message stays, in milliseconds. Longer for an error, so that it is not missed
  # (WCAG 2.2.1); paused while the pointer or the keyboard focus is on it
  MESSAGE_VARIANTS = {
    error: {
      classes: "border-error-ink/70 bg-error-bg text-error-ink",
      role: "alert",
      icon: "shared/icons/x",
      toast_icon: "bg-error-bg text-error-ink",
      toast_duration: 10_000
    },
    success: {
      classes: "border-success-ink/70 bg-success-bg text-success-ink",
      role: "status",
      icon: "shared/icons/check",
      toast_icon: "bg-success-bg text-success-ink",
      toast_duration: 5_000
    }
  }.freeze

  def message_classes(variant)
    "#{MESSAGE_BASE_CLASSES} #{MESSAGE_VARIANTS.fetch(variant)[:classes]}"
  end

  # alert is announced at once by screen readers, status when they are idle
  def message_role(variant)
    MESSAGE_VARIANTS.fetch(variant)[:role]
  end

  def message_icon(variant)
    MESSAGE_VARIANTS.fetch(variant)[:icon]
  end

  # Above the page, out of its flow, like a notification (decision): across the top of a phone, in the top right
  # corner from 768 px. It was at the bottom while an error stayed until it was closed (it covered the close button
  # of the settings window, "Create a table" and the theme control); every message now leaves by itself
  TOAST_STACK_CLASSES = "fixed inset-x-4 top-4 z-50 flex flex-col gap-2 " \
                        "md:inset-x-auto md:top-6 md:right-6 md:w-96".freeze

  # On the surface of the theme, with a shadow; slides down when it comes, fades out when it leaves (data-leaving,
  # set by toast_controller.js). Nothing moves for those who ask their device for less motion
  TOAST_CLASSES = "flex items-start gap-3 rounded-xl border border-line bg-surface p-3.5 text-sm text-ink " \
                  "shadow-lg motion-safe:animate-toast-in motion-safe:transition " \
                  "motion-safe:duration-200 data-leaving:opacity-0 motion-safe:data-leaving:-translate-y-2".freeze

  TOAST_ICON_CLASSES = "inline-flex size-6 shrink-0 items-center justify-center rounded-full".freeze

  # 24 px, the minimum size of a target (WCAG 2.5.8)
  TOAST_CLOSE_BUTTON_CLASSES = "-my-0.5 -mr-1 inline-flex size-6 shrink-0 cursor-pointer items-center " \
                               "justify-center rounded-md text-muted hover:bg-surface-raised hover:text-ink".freeze

  # The messages of shared/_flashes that show on screen (flash[:screen_reader_notice] does not)
  def visible_messages?
    visible_flash_messages.any?
  end

  # [[variant, message]], the success first
  def visible_flash_messages
    { success: flash[:notice], error: flash[:alert] }.compact_blank.to_a
  end

  def toast_stack_classes
    TOAST_STACK_CLASSES
  end

  def toast_classes
    TOAST_CLASSES
  end

  def toast_icon_classes(variant)
    "#{TOAST_ICON_CLASSES} #{MESSAGE_VARIANTS.fetch(variant)[:toast_icon]}"
  end

  def toast_duration(variant)
    MESSAGE_VARIANTS.fetch(variant)[:toast_duration]
  end

  def toast_close_button_classes
    TOAST_CLOSE_BUTTON_CLASSES
  end

  # Replaces Simple Form's f.error_notification. On screen, the red field and its message are enough;
  # this summary stays for screen readers only (sr-only): its alert role tells them the form has errors
  def form_error_notification(form)
    return if form.object.errors.none?

    content_tag(:div, class: "sr-only") do
      render(layout: "shared/message", locals: { variant: :error }) do
        t("simple_form.error_notification.default_message")
      end
    end
  end
end
