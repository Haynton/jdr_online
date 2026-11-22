# Checks the values of a player character sheet against the fields of the template copied into its table:
# JSONB has no check of its own in the database. A wrong value gets its error on "sheet.<key of the field>",
# shown under that field of the form. Only the player characters for now (NPCs and monsters: P4)
class CharacterSheetValidator < ActiveModel::Validator
  TEXT_MAX_LENGTH = 2000

  def validate(character)
    return unless character.pc? && character.game_table

    fields_by_key = character.sheet_fields.index_by { |field| field["key"] }
    character.sheet.each do |key, value|
      error_type, error_options = value_error(fields_by_key[key], value)
      character.errors.add(:"sheet.#{key}", error_type, **error_options.to_h) if error_type
    end
    validate_required_fields(character)
  end

  private

  # The fields marked required in the step being saved (Character#fill_step): the step stays until they are filled
  def validate_required_fields(character)
    character.required_sheet_fields.to_a.each do |field|
      character.errors.add(:"sheet.#{field['key']}", :blank) if character.sheet[field["key"]].blank?
    end
  end

  # nil when the value fits its field, otherwise the type of the error and its options
  def value_error(field, value)
    case field&.dig("type")
    when "number" then number_error(value, minimum: field["min"], maximum: field["max"], step: field["step"])
    when "ability" then number_error(value, minimum: field["min"], maximum: field["max"])
    when "experience" then number_error(value, minimum: 0)
    when "resource" then resource_error(value)
    # A bonus stores only its proficiency, ticked or not; a computed field is never stored (else branch)
    when "boolean", "bonus" then [:inclusion] unless [true, false].include?(value)
    when "choice" then [:inclusion] unless field["options"].include?(value)
    when "text" then text_error(value)
    else [:invalid]
    end
  end

  def number_error(value, minimum:, maximum: nil, step: nil)
    return (decimal_step?(step) ? [:invalid] : [:not_an_integer]) unless allowed_number?(value, step)
    return [:greater_than_or_equal_to, { count: minimum }] if minimum && value < minimum

    [:less_than_or_equal_to, { count: maximum }] if maximum && value > maximum
  end

  # A step under 1 (half metres: 10.5) allows the multiples of that step; otherwise only integers
  def allowed_number?(value, step)
    return value.is_a?(Integer) unless decimal_step?(step)

    value.is_a?(Numeric) && ((value / step.to_f).round(6) % 1).zero?
  end

  def decimal_step?(step)
    step.to_f.positive? && step.to_f < 1
  end

  # A resource is its current value and its maximum ("PV 8 / 12"): at creation, both are the maximum
  def resource_error(value)
    return [:not_an_integer] unless value.is_a?(Hash) && value.values_at("current", "max").all?(Integer)
    return [:greater_than_or_equal_to, { count: 0 }] if value["max"].negative?

    [:invalid] unless value["current"].between?(0, value["max"])
  end

  def text_error(value)
    return [:invalid] unless value.is_a?(String)

    [:too_long, { count: TEXT_MAX_LENGTH }] if value.length > TEXT_MAX_LENGTH
  end
end
