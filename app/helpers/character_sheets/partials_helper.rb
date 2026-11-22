# Which partial draws what on a character sheet: a field by its type (character_sheets/fields), a section by its layout
# (character_sheets/sections, CharacterSheets::LayoutHelper#sheet_section_layout). The paths are written in full: a
# search for a partial finds who draws it
module CharacterSheets
  module PartialsHelper
    # The partial that draws each type, wherever it is (character_sheets/fields); a choice or a text is a field to fill
    # in (INPUT_FIELD_PARTIAL). Written in full: a search for a partial finds who draws it
    FIELD_PARTIALS = {
      "ability" => "character_sheets/fields/ability", "number" => "character_sheets/fields/stat",
      "resource" => "character_sheets/fields/stat", "experience" => "character_sheets/fields/stat",
      "computed" => "character_sheets/fields/stat", "boolean" => "character_sheets/fields/switch",
      "bonus" => "character_sheets/fields/bonus", "picks" => "character_sheets/fields/picks"
    }.freeze
    INPUT_FIELD_PARTIAL = "character_sheets/fields/input".freeze
    # The partial of each layout of a section (sheet_section_layout), in full for the same reason
    SECTION_PARTIALS = {
      described_choices: "character_sheets/sections/described_choices",
      abilities: "character_sheets/sections/abilities",
      rows: "character_sheets/sections/rows",
      two_columns: "character_sheets/sections/two_columns",
      split: "character_sheets/sections/split",
      flow: "character_sheets/sections/flow"
    }.freeze

    # The look of a field, by its type only (FIELD_PARTIALS); a choice or a text is a field to fill in
    def sheet_field_partial(field)
      FIELD_PARTIALS.fetch(field["type"], INPUT_FIELD_PARTIAL)
    end

    def sheet_section_partial(layout)
      SECTION_PARTIALS.fetch(layout)
    end
  end
end
