module ButtonsHelper
  BUTTON_BASE_CLASSES = %w[
    inline-flex items-center justify-center gap-2 rounded-lg font-semibold transition-colors
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
    disabled:cursor-not-allowed disabled:opacity-50
  ].join(" ").freeze

  BUTTON_VARIANT_CLASSES = {
    primary: "bg-primary text-white hover:bg-primary-hover",
    secondary: "border border-line bg-surface text-ink hover:bg-surface-raised",
    quiet: "bg-transparent text-ink hover:bg-surface-raised",
    # Filled, like primary: an outlined red button did not stand out enough in the light theme
    danger: "bg-danger text-white hover:bg-danger-hover"
  }.freeze

  BUTTON_SIZE_CLASSES = {
    normal: "h-11 px-4 text-sm",
    compact: "h-9 px-3 text-sm"
  }.freeze

  def button_classes(variant, size: :normal)
    [BUTTON_BASE_CLASSES, BUTTON_VARIANT_CLASSES.fetch(variant), BUTTON_SIZE_CLASSES.fetch(size)].join(" ")
  end
end
