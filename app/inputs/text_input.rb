# Replaces Simple Form's text input (Simple Form looks for a class with this exact name): a <textarea> keeps the
# look of the other fields (SimpleFormFieldClasses::INPUT) but not their fixed height of 40 px.
# It starts at four lines and the user can make it taller, unless the view gives a minimum height of its own
# (input_html class min-h-..., with rows: the description of a template, 2 lines): both together, Tailwind would let
# min-h-24 win, written later in its CSS
class TextInput < SimpleForm::Inputs::TextInput
  FIXED_HEIGHT_CLASSES = %w[h-10 py-1.5].freeze
  TEXTAREA_CLASSES = "resize-y py-2 leading-relaxed".freeze
  DEFAULT_MINIMUM_HEIGHT = "min-h-24".freeze

  def input(wrapper_options = nil)
    super(with_textarea_classes(wrapper_options))
  end

  private

  def with_textarea_classes(wrapper_options)
    options = wrapper_options.to_h
    field_classes = options[:class].to_s.split - FIXED_HEIGHT_CLASSES
    options.merge(class: [*field_classes, TEXTAREA_CLASSES, minimum_height].compact.join(" "))
  end

  def minimum_height
    DEFAULT_MINIMUM_HEIGHT unless Array(input_html_options[:class]).join(" ").include?("min-h-")
  end
end
