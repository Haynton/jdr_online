require "zlib"

# Where the fields of a character sheet go (the fields themselves: CharacterSheetsHelper). The sheet is laid out by
# field type, like a sheet of a game (decision): abilities in tiles, short numbers in small boxes side by side,
# saving throws and skills in tight rows, choices at a medium width, texts across the width
module CharacterSheetLayoutHelper
  # The width of a field in a section laid out as a flow. 160 px for a short number: its label fits on one line
  FIELD_WIDTH_CLASSES = {
    "text" => "w-full", "choice" => "w-full sm:w-56", "boolean" => "w-full sm:w-auto sm:pt-7"
  }.freeze
  NARROW_FIELD_WIDTH_CLASSES = "w-40".freeze
  NARROW_FIELD_TYPES = %w[number resource experience computed].freeze

  # The fields by section ("Caractéristiques", "Compétences"...), in the order of the template
  def sheet_sections(fields)
    fields.group_by { |field| field["section"] }
  end

  # abilities: tiles side by side; rows: saving throws and skills; flow: anything else, each field at its width
  def sheet_section_layout(fields)
    return :abilities if fields.all? { |field| field["has_modifier"] }
    return :rows if fields.all? { |field| field["type"] == "bonus" }

    :flow
  end

  # The help of the rows of a section, said once under its title rather than under one of its rows
  def sheet_section_helps(fields)
    fields.filter_map { |field| field["help"] }.uniq
  end

  # The partial of a field in a flow section: a check box beside its label, a computed value, or a field to fill in
  def sheet_field_partial(field)
    case field["type"]
    when "boolean" then "check_box_field"
    when "computed" then "computed_field"
    else "input_field"
    end
  end

  def sheet_field_width_classes(field)
    FIELD_WIDTH_CLASSES.fetch(field["type"], NARROW_FIELD_WIDTH_CLASSES)
  end

  # A short field keeps its help out of its narrow column: the helps of a section go under its row, across the width
  def sheet_field_narrow?(field)
    NARROW_FIELD_TYPES.include?(field["type"])
  end

  # The helps of the short fields of a section, under its row. Fields with the same help share one note
  # ("Points de vie, Points de vie temporaires : valeur maximale..."), which each of them points to
  def sheet_section_notes(fields)
    narrow_fields = fields.select { |field| sheet_field_narrow?(field) && sheet_field_hint(field) }
    narrow_fields.group_by { |field| sheet_field_hint(field) }.map do |text, note_fields|
      { id: sheet_note_id(text), labels: note_fields.pluck("label").to_sentence, text: text }
    end
  end

  # The same help gives the same id: a field finds its note without knowing its section
  def sheet_note_id(text)
    "character_sheet_note_#{Zlib.crc32(text)}"
  end
end
