# Turns what a player typed in the sheet form (always text) into the values of characters.sheet, by field type:
# numbers become integers, a resource its current value and maximum, a check box true or false.
# A blank field is left out: the sheet only keeps what was filled in. A value that cannot be converted is kept
# as typed, so that CharacterSheetValidator refuses it and the form shows it again under its error
class CharacterSheetBuilder
  def initialize(fields:, submitted_values:)
    @fields = fields
    @submitted_values = submitted_values.to_h.stringify_keys
  end

  # Check boxes (a boolean, the proficiency of a bonus) are always kept: unchecked is a value too.
  # A computed field is never stored (CharacterSheetCalculator)
  CHECK_BOX_TYPES = %w[boolean bonus].freeze

  def call
    @fields.each_with_object({}) do |field, sheet|
      typed_value = @submitted_values[field["key"]]
      next if field["type"] == "computed"
      next if blank_value?(field, typed_value)

      sheet[field["key"]] = convert(field, typed_value)
    end
  end

  private

  # An equipment option without an option picked is blank too (its picks alone mean nothing)
  def blank_value?(field, typed_value)
    return typed_value.to_h.stringify_keys["option"].blank? if field["type"] == "equipment_option"

    typed_value.blank? && CHECK_BOX_TYPES.exclude?(field["type"])
  end

  def convert(field, typed_value)
    case field["type"]
    when "number" then number_or_typed_value(field, typed_value)
    when "ability", "experience" then integer_or_typed_value(typed_value)
    when "resource" then full_resource(typed_value)
    # The check boxes of the options picked; the hidden field before them sends "" so that none picked is a value too
    when "picks" then Array(typed_value).compact_blank.map(&:to_s)
    # One choice (0, 1 or 2) per ability raised; a bonus of 0 is left out
    when "ability_bonuses" then ability_bonuses(typed_value)
    when "equipment_option" then equipment_option(typed_value)
    # The check box sends "1" when checked, the hidden field before it "0". For a bonus, it is its proficiency
    when *CHECK_BOX_TYPES then typed_value == "1"
    else typed_value.to_s.strip
    end
  end

  def integer_or_typed_value(typed_value)
    Integer(typed_value.to_s.strip, 10, exception: false) || typed_value
  end

  # A number with a step under 1 takes decimals, typed with a point or a comma (10,5 m); a whole value stays an
  # integer (9, not 9.0)
  def number_or_typed_value(field, typed_value)
    return integer_or_typed_value(typed_value) if field["step"].to_f.zero? || field["step"].to_f >= 1

    number = Float(typed_value.to_s.strip.tr(",", "."), exception: false)
    return typed_value unless number

    number == number.to_i ? number.to_i : number
  end

  def ability_bonuses(typed_value)
    bonuses = typed_value.to_h.transform_values { |bonus| Integer(bonus.to_s, 10, exception: false) || bonus }
    bonuses.reject { |_ability_key, bonus| bonus.is_a?(Integer) && bonus.zero? }
  end

  # The option picked (a, b, c) and the items of your choice of that option only (the lists of every option are
  # sent: picks[a][2]), those not picked left out (StartingEquipment)
  def equipment_option(typed_value)
    value = typed_value.to_h.stringify_keys
    option = value["option"].to_s
    picks = value["picks"].to_h.stringify_keys[option].to_h.stringify_keys.compact_blank
    { "option" => option, "picks" => picks }
  end

  # At creation, the player gives the maximum: the character starts full
  def full_resource(typed_value)
    maximum = Integer(typed_value.to_s.strip, 10, exception: false)
    maximum ? { "current" => maximum, "max" => maximum } : typed_value
  end
end
