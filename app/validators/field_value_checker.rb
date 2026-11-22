# Whether a value fits its field of a template (its type, its bounds, its options): the values of a character sheet
# (CharacterSheetValidator) and the properties of a catalog entry (CatalogPropertiesValidator) are checked with the
# same rules
class FieldValueChecker
  TEXT_MAX_LENGTH = 2000

  # nil when the value fits its field, otherwise the type of the error and its options ([:too_long, { count: 2000 }])
  def self.error_for(field, value)
    new.error_for(field, value)
  end

  def error_for(field, value)
    case field&.dig("type")
    when "number", "ability" then number_error(value, minimum: field["min"], maximum: field["max"], step: field["step"])
    when "experience" then number_error(value, minimum: 0)
    when "resource" then resource_error(value)
    # A bonus stores only its proficiency, ticked or not; a computed field is never stored (else branch)
    when "boolean", "bonus" then [:inclusion] unless [true, false].include?(value)
    when "choice" then [:inclusion] unless field["options"].include?(value)
    when "picks" then picks_error(value, field)
    when "text" then text_error(value)
    else [:invalid]
    end
  end

  private

  # Options of the list only, count at most
  def picks_error(value, field)
    return [:inclusion] unless value.is_a?(Array) && (value - field["options"].to_a).empty?

    [:too_many_picks, { count: field["count"] }] if field["count"] && value.size > field["count"]
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
