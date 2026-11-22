module MessagesHelper
  # The tinted background and pale *-line border alone barely show (1.04 to 2.02 against the page):
  # a 1 px border in the text color at 70 % reaches 3.32 to 7.24, softer than the full color
  MESSAGE_BASE_CLASSES = "flex items-start gap-2 rounded-lg border px-3.5 py-3 text-[13px]".freeze

  MESSAGE_VARIANTS = {
    error: {
      classes: "border-error-ink/70 bg-error-bg text-error-ink",
      role: "alert",
      icon: "x"
    },
    success: {
      classes: "border-success-ink/70 bg-success-bg text-success-ink",
      role: "status",
      icon: "check"
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

  # Above the page, out of its flow: at the bottom of a phone, over the floating navigation bar (56 px, 16 px from
  # the bottom), in the bottom right corner from 768 px. Not at the top: an error, which stays until it is closed,
  # covered the close button of the settings window, "Create a table" and the theme control
  TOAST_STACK_CLASSES = "fixed inset-x-4 bottom-24 z-50 flex flex-col gap-2 " \
                        "md:inset-x-auto md:right-6 md:bottom-6 md:w-96".freeze

  # 24 px, the minimum size of a target (WCAG 2.5.8), in the color of the message text
  TOAST_CLOSE_BUTTON_CLASSES = "-my-1 -mr-1.5 inline-flex size-6 shrink-0 cursor-pointer items-center " \
                               "justify-center rounded-md hover:bg-current/10".freeze

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
