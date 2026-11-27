# Which partial draws what on a character sheet: a field by its type (its class of app/models/field_types says it), a
# section by its layout (character_sheets/sections, CharacterSheets::LayoutHelper#sheet_section_layout). The paths are
# written in full: a search for a partial finds who draws it
module CharacterSheets
  module PartialsHelper
    # The partial of each layout of a section (sheet_section_layout), in full for the same reason
    SECTION_PARTIALS = {
      option_cards: "character_sheets/sections/option_cards",
      described_choices: "character_sheets/sections/described_choices",
      abilities: "character_sheets/sections/abilities",
      rows: "character_sheets/sections/rows",
      two_columns: "character_sheets/sections/two_columns",
      split: "character_sheets/sections/split",
      flow: "character_sheets/sections/flow"
    }.freeze

    # The look of a field, said by its type (FieldTypes::Base#partial: the paths are written in full in the classes
    # of app/models/field_types)
    def sheet_field_partial(field)
      FieldTypes.of(field).partial_for(field)
    end

    def sheet_section_partial(layout)
      SECTION_PARTIALS.fetch(layout)
    end
  end
end
