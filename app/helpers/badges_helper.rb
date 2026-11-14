module BadgesHelper
  # Pill shape, uppercase and tonal colors: a badge must never be mistaken for a button,
  # so solid primary stays reserved to buttons
  BADGE_BASE_CLASSES = %w[
    inline-flex items-center rounded-full px-2.5 py-1 text-[11px] leading-4 font-bold tracking-wide uppercase
  ].join(" ").freeze

  # The inner ring draws the pill on a card: in the dark theme the badge backgrounds alone
  # are almost the card color (1.18 and 1.04), the ring at 50 % of the text color reaches 3.49 and 3.78
  BADGE_VARIANT_CLASSES = {
    game_master: "bg-primary-soft text-primary-soft-ink ring-1 ring-inset ring-primary-soft-ink/50",
    player: "bg-success-bg text-success-ink ring-1 ring-inset ring-success-ink/50"
  }.freeze

  def badge_classes(variant)
    "#{BADGE_BASE_CLASSES} #{BADGE_VARIANT_CLASSES.fetch(variant)}"
  end
end
