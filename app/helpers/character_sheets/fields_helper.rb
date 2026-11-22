# The fields of a character sheet come from the template of the table (JSONB), not from columns: Simple Form cannot read
# them as attributes (and a key such as "class" would clash with Ruby). They are drawn here, with the classes of the
# Simple Form fields (config/initializers/simple_form.rb and app/inputs/), so that they look the same and the style
# stays written in one place. Each control is named character[sheet][<key>] (CharacterSheets::Builder). Where the fields
# go on the page: CharacterSheets::LayoutHelper. How computed values read: CharacterSheets::ValuesHelper
module CharacterSheets
  module FieldsHelper
    TEXTAREA_CLASSES = [
      *(SimpleFormFieldClasses::INPUT.split - TextInput::FIXED_HEIGHT_CLASSES), TextInput::TEXTAREA_CLASSES
    ].join(" ").freeze
    SELECT_CLASSES = "#{SimpleFormFieldClasses::INPUT} #{CollectionSelectInput::SELECT_CLASSES}".freeze
    # A number field without the small arrows of the browser (decision: they cluttered the tiles and boxes)
    NO_ARROWS_CLASSES = %w[
      [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none
      [&::-webkit-outer-spin-button]:appearance-none
    ].freeze
    # A number between its "−" and "+" buttons (decision: they show that the value changes), in a tile or a box.
    # The field look, narrow and centered
    STEPPER_INPUT_CLASSES = [
      *(SimpleFormFieldClasses::INPUT.split - %w[block w-full px-3]),
      "w-12 shrink-0 px-0 text-center text-base font-semibold", *NO_ARROWS_CLASSES
    ].join(" ").freeze

    def sheet_field_id(field)
      "character_sheet_#{field['key']}"
    end

    def sheet_field_error(character, field)
      character.errors[:"sheet.#{field['key']}"].first
    end

    # A resource shows its maximum: the character starts full (CharacterSheets::Builder)
    def sheet_field_hint(field)
      return t("game_tables.characters.new.resource_hint") if field["type"] == "resource"

      field["help"]
    end

    # The abbreviation of the ability a bonus is based on (DEX), from the ability field itself
    def sheet_ability_abbreviation(fields, ability_key)
      ability = fields.find { |field| field["key"] == ability_key }
      ability && (ability["abbreviation"] || ability["label"])
    end

    # A choice or a text (character_sheets/fields/_input): a short text (short: true) is one line, any other a text area
    def sheet_field_control(character, field)
      return sheet_select(character, field) if field["type"] == "choice"

      field["short"] ? sheet_text_field(character, field) : sheet_text_area(character, field)
    end

    # A number between "−" and "+" (character_sheets/fields/_stepper), in a tile or a box
    def sheet_stepper_input(character, field, data: {}, autocomplete: nil)
      options = sheet_number_options(character, field).merge(class: STEPPER_INPUT_CLASSES, autocomplete: autocomplete,
                                                             data: { number_stepper_target: "input", **data })
      number_field_tag(sheet_field_name(field), sheet_field_value(character, field), options)
    end

    # The score of an ability: the live calculation reads it to work out its modifier, and shows the bonus of the
    # background in it. autocomplete off: a browser that restored the score shown (bonus included) on coming back to
    # the page would get the bonus added twice
    def sheet_ability_input(character, field)
      sheet_stepper_input(character, field, autocomplete: "off",
                                            data: { character_sheet_target: "score", ability: field["key"],
                                                    modifier_rule: field["modifier"] })
    end

    # The hidden "0" first: an unchecked box sends nothing on its own. For a bonus, the box is its proficiency
    def sheet_check_box(character, field, data: {})
      hidden_field_tag(sheet_field_name(field), "0", id: nil) +
        check_box_tag(sheet_field_name(field), "1", character.sheet[field["key"]] == true,
                      sheet_control_options(character, field)
                        .merge(class: SimpleFormFieldClasses::CHECKBOX, data: data))
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

    # The bounds of the field (min and max of the template; an experience or a resource starts at 0)
    def sheet_number_options(character, field)
      bounds = { min: %w[number ability].include?(field["type"]) ? field["min"] : 0, max: field["max"],
                 step: field["step"] }.compact
      sheet_control_options(character, field).merge(class: SimpleFormFieldClasses::INPUT, **bounds)
    end

    def sheet_text_field(character, field, options = nil)
      options ||= sheet_control_options(character, field).merge(class: SimpleFormFieldClasses::INPUT)
      text_field_tag(sheet_field_name(field), sheet_field_value(character, field), options.except(:min, :max))
    end

    def sheet_text_area(character, field)
      text_area_tag(sheet_field_name(field), sheet_field_value(character, field),
                    sheet_control_options(character, field).merge(class: TEXTAREA_CLASSES, rows: 3))
    end

    # The chevron of CollectionSelectInput, over the native select
    # A list whose options have effects (SheetTemplate::CHOICE_EFFECTS): the live calculation applies them when
    # the player picks an option (character_sheet_controller.js#applyEffects)
    def sheet_choice_effects_data(field)
      return {} unless field["effects"]

      { character_sheet_target: "effectChoice", effects: field["effects"].to_json,
        action: "character-sheet#applyEffects" }
    end

    def sheet_select(character, field)
      tag.div(class: "relative") do
        select_tag(sheet_field_name(field),
                   options_for_select(field["options"], sheet_field_value(character, field)),
                   sheet_control_options(character, field).merge(class: SELECT_CLASSES, include_blank: true,
                                                                 data: sheet_choice_effects_data(field))) +
          render("shared/icons/chevron_down", css_class: CollectionSelectInput::CHEVRON_CLASSES)
      end
    end
  end
end
