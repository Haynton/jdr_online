# Replaces Simple Form's select input (Simple Form looks for a class with this exact name).
# Keeps the native <select>, usable with the keyboard and on mobile, hides the browser arrow
# and shows the chevron icon in its place. The icon lets clicks through to the select.
# select-picker styles the open list where the browser allows it (see app/assets/tailwind/application.css).
class CollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
  SELECT_CLASSES = "select-picker cursor-pointer appearance-none pr-10".freeze
  CHEVRON_CLASSES = "pointer-events-none absolute top-1/2 right-3.5 size-4 -translate-y-1/2 text-muted".freeze

  def input(wrapper_options = nil)
    template.content_tag(:div, class: "relative") do
      super(with_select_classes(wrapper_options)) + chevron_icon
    end
  end

  private

  def with_select_classes(wrapper_options)
    options = wrapper_options.to_h
    options.merge(class: [options[:class], SELECT_CLASSES].compact.join(" "))
  end

  def chevron_icon
    template.render("shared/icons/chevron_down", css_class: CHEVRON_CLASSES)
  end
end
