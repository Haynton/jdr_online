module ButtonsHelper
  PRIMARY_BUTTON_CLASSES = %w[
    rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-white hover:bg-primary-hover
  ].join(" ").freeze

  def primary_button_classes
    PRIMARY_BUTTON_CLASSES
  end
end
