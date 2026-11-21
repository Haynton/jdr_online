# Replaces Simple Form's text input (Simple Form looks for a class with this exact name): a <textarea> keeps the
# look of the other fields (SimpleFormFieldClasses::INPUT) but not their fixed height of 40 px.
# It starts at four lines and the user can make it taller
class TextInput < SimpleForm::Inputs::TextInput
  FIXED_HEIGHT_CLASSES = %w[h-10 py-1.5].freeze
  TEXTAREA_CLASSES = "min-h-24 resize-y py-2 leading-relaxed".freeze

  def input(wrapper_options = nil)
    super(with_textarea_classes(wrapper_options))
  end

  private

  def with_textarea_classes(wrapper_options)
    options = wrapper_options.to_h
    field_classes = options[:class].to_s.split - FIXED_HEIGHT_CLASSES
    options.merge(class: [*field_classes, TEXTAREA_CLASSES].join(" "))
  end
end
