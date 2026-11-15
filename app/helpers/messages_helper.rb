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
