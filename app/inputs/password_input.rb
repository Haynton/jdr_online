# Replaces Simple Form's password input (Simple Form looks for a class with this exact name).
# Every password field gets a button, inside the field on the right, that shows or hides what is typed.
# The behavior lives in password_visibility_controller.js; the field keeps room on its right for the button.
class PasswordInput < SimpleForm::Inputs::PasswordInput
  FIELD_CLASSES = "pr-12".freeze
  CONTROLLER_DATA = { controller: "password-visibility", action: "submit@document->password-visibility#hide" }.freeze

  def input(wrapper_options = nil)
    template.content_tag(:div, class: "relative", data: CONTROLLER_DATA) do
      super(with_field_options(wrapper_options)) + visibility_button
    end
  end

  private

  def with_field_options(wrapper_options)
    options = wrapper_options.to_h
    options.merge(
      class: [options[:class], FIELD_CLASSES].compact.join(" "),
      data: { password_visibility_target: "field" }
    )
  end

  def visibility_button
    template.render("shared/password_visibility_button")
  end
end
