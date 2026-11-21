# The fields of a character sheet come from the template of the table (JSONB), not from columns: Simple Form cannot
# read them as attributes (and a key such as "class" would clash with Ruby). They are drawn here, with the classes
# of the Simple Form fields (config/initializers/simple_form.rb and app/inputs/), so that they look the same and
# the style stays written in one place. Each control is named character[sheet][<key>] (CharacterSheetBuilder).
# Where the fields go on the page: CharacterSheetLayoutHelper
module CharacterSheetsHelper
  TEXTAREA_CLASSES = [
    *(SimpleFormFieldClasses::INPUT.split - TextInput::FIXED_HEIGHT_CLASSES), TextInput::TEXTAREA_CLASSES
  ].join(" ").freeze
  SELECT_CLASSES = "#{SimpleFormFieldClasses::INPUT} #{CollectionSelectInput::SELECT_CLASSES}".freeze
  # The score of an ability, between its "−" and "+" buttons (decision: they show that the value changes).
  # The field look, narrow and centered, without the arrows of a number field: the buttons do their job
  ABILITY_INPUT_CLASSES = [
    *(SimpleFormFieldClasses::INPUT.split - %w[block w-full px-3]),
    "w-12 shrink-0 px-0 text-center text-base font-semibold",
    "[appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none",
    "[&::-webkit-outer-spin-button]:appearance-none"
  ].join(" ").freeze
  # A computed value, shown in place of a field: read only, so a border and no field background
  COMPUTED_VALUE_CLASSES = %w[
    flex h-10 items-center rounded-lg border border-line px-3 text-sm font-semibold text-ink
  ].join(" ").freeze

  def sheet_field_id(field)
    "character_sheet_#{field['key']}"
  end

  def sheet_field_error(character, field)
    character.errors[:"sheet.#{field['key']}"].first
  end

  # A resource shows its maximum: the character starts full (CharacterSheetBuilder)
  def sheet_field_hint(field)
    return t("game_tables.characters.new.resource_hint") if field["type"] == "resource"

    field["help"]
  end

  # +2, -1, or a dash while it cannot be worked out (no score yet). Same as formatBonus in character_sheet_controller.js
  def format_bonus(value)
    return "—" if value.nil?

    value.negative? ? value.to_s : "+#{value}"
  end

  # The abbreviation of the ability a bonus is based on (DEX), from the ability field itself
  def sheet_ability_abbreviation(fields, ability_key)
    ability = fields.find { |field| field["key"] == ability_key }
    ability && (ability["abbreviation"] || ability["label"])
  end

  def sheet_field_control(character, field)
    case field["type"]
    when "choice" then sheet_select(character, field)
    when "text" then sheet_text_area(character, field)
    else number_field_tag(sheet_field_name(field), sheet_field_value(character, field),
                          sheet_number_options(character, field))
    end
  end

  # The score of an ability: the live calculation reads it to work out its modifier
  def sheet_ability_input(character, field)
    calculation_data = { character_sheet_target: "score", number_stepper_target: "input", ability: field["key"] }
    options = sheet_number_options(character, field).merge(class: ABILITY_INPUT_CLASSES, data: calculation_data)
    number_field_tag(sheet_field_name(field), sheet_field_value(character, field), options)
  end

  # The hidden "0" first: an unchecked box sends nothing on its own. For a bonus, the box is its proficiency
  def sheet_check_box(character, field, data: {})
    hidden_field_tag(sheet_field_name(field), "0", id: nil) +
      check_box_tag(sheet_field_name(field), "1", character.sheet[field["key"]] == true,
                    sheet_control_options(character, field).merge(class: SimpleFormFieldClasses::CHECKBOX, data: data))
  end

  private

  def sheet_field_name(field)
    "character[sheet][#{field['key']}]"
  end

  def sheet_field_value(character, field)
    value = character.sheet[field["key"]]
    value.is_a?(Hash) ? value["max"] : value
  end

  # The note of a short field (under the row of its section) and the message under an invalid field are tied to it:
  # screen readers read them with the field
  def sheet_control_options(character, field)
    invalid = sheet_field_error(character, field).present?
    described_by = [sheet_field_note_ids(field), ("#{sheet_field_id(field)}_error" if invalid)].flatten.compact
    aria = { invalid: (true if invalid), describedby: described_by.join(" ").presence }.compact
    { id: sheet_field_id(field), aria: aria }
  end

  def sheet_field_note_ids(field)
    hint = sheet_field_hint(field)
    sheet_field_narrow?(field) && hint ? [sheet_note_id(hint)] : []
  end

  # The experience field tells the live calculation that the level may change
  def sheet_number_options(character, field)
    bounds = { min: field["type"] == "number" ? field["min"] : 0, max: field["max"] }
    options = sheet_control_options(character, field).merge(class: SimpleFormFieldClasses::INPUT, **bounds)
    field["type"] == "experience" ? options.merge(data: { character_sheet_target: "experience" }) : options
  end

  def sheet_text_area(character, field)
    text_area_tag(sheet_field_name(field), sheet_field_value(character, field),
                  sheet_control_options(character, field).merge(class: TEXTAREA_CLASSES, rows: 3))
  end

  # The chevron of CollectionSelectInput, over the native select
  def sheet_select(character, field)
    tag.div(class: "relative") do
      select_tag(sheet_field_name(field),
                 options_for_select(field["options"], sheet_field_value(character, field)),
                 sheet_control_options(character, field).merge(class: SELECT_CLASSES, include_blank: true)) +
        render("shared/icons/chevron_down", css_class: CollectionSelectInput::CHEVRON_CLASSES)
    end
  end
end
