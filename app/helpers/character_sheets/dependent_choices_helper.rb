# A list that depends on another list or on a level (the subclass: those of the class picked, from level 3), on the
# steps of the creation of a character: hidden while the sheet does not ask it, and followed on the page by
# dependent_choice_controller.js, as FieldTypes::Choice does on the server
module CharacterSheets
  module CharacterSheets::DependentChoicesHelper
    # A field the sheet does not ask yet (the subclass, before level 3) is in the page, hidden: the level or the list
    # it depends on may change on the same page (dependent_choice_controller.js)
    def sheet_field_asked?(character, field)
      FieldTypes.of(field).asked_on?(field, character.sheet)
    end

    # A list that depends on another or on a level follows them on the page, as FieldTypes::Choice on the server: its
    # options, the field shown or hidden with what goes with it (its summary, data-shown-with)
    def sheet_dependent_choice_data(character, field)
      return {} unless field["options_from"] || field["from_level"]

      { controller: "dependent-choice",
        action: "change@window->dependent-choice#refresh input@window->dependent-choice#refresh",
        dependent_choice_field_key_value: field["key"], dependent_choice_options_from_value: field["options_from"],
        dependent_choice_options_by_value: field["options_by"].to_json,
        dependent_choice_saved_option_value: character.sheet[field["options_from"]],
        dependent_choice_from_level_value: field["from_level"], dependent_choice_level_from_value: field["level_from"],
        dependent_choice_saved_level_value: character.sheet[field["level_from"]] }.compact
    end
  end
end
