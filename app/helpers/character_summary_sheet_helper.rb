# The summary of the creation of a character, laid out like a character sheet (game_tables/character_steps/_summary,
# decision: a list of values was hard to read). Each step is a block of the sheet, with "Change" to go back to it; in
# a block, the fields are read-only and grouped by type, one look per type as on the steps: facts (lists, short texts,
# yes or no), ability tiles, boxes (numbers, resources, worked out values), rows (saving throws, skills), long texts.
# Read from any template: the heroic fantasy gives a sheet with its abilities across the width and three columns
module CharacterSummarySheetHelper
  SUMMARY_GROUPS = %i[facts tiles boxes rows texts].freeze
  BOX_TYPES = %w[number resource experience computed].freeze

  # The step that names the character opens the sheet, across the width (its name, its class, its species...)
  def summary_header_step(steps)
    steps.find(&:asks_name)
  end

  # The blocks under the header in two columns from 1024 px (decision): the steps made mostly of rows (saving throws,
  # skills), the longest, on the right; the others (abilities, combat, spells, details) on the left, in the order of
  # the template. An empty column is left out
  def summary_columns(steps)
    rows_steps, other_steps = steps.partition { |step| summary_rows_step?(step) }
    [other_steps, rows_steps].reject(&:empty?)
  end

  def summary_rows_step?(step)
    groups = step.fields.map { |field| summary_group(field) }
    groups.count(:rows) > groups.size / 2
  end

  # The fields of a step by group, in the order of SUMMARY_GROUPS, each group in the order of the template
  # The bonus of the background is not shown as a field: it is in the scores of the tiles already
  def summary_groups(fields)
    # The bonus of the background is in the scores, the equipment in its own list (summary_equipment), and an internal
    # value (the starting gold, which fills the gold of the sheet) is shown nowhere
    shown_fields = fields.reject do |field|
      field["internal"] || %w[ability_bonuses equipment_option].include?(field["type"])
    end
    grouped_fields = shown_fields.group_by { |field| summary_group(field) }
    SUMMARY_GROUPS.filter_map { |group| [group, grouped_fields[group]] if grouped_fields[group] }
  end

  # A value given by the table (the level) reads with the facts of the header, not in a box
  def summary_group(field)
    return :facts if field["from_table"]
    return :tiles if field["type"] == "ability"
    return :rows if field["type"] == "bonus"
    return :boxes if BOX_TYPES.include?(field["type"])
    return :texts if field["type"] == "text" && !field["short"]

    :facts
  end

  # The value of a field as written on a sheet, or a dash while it is empty
  def summary_value(character, field, computed)
    text = if field["type"] == "computed"
             computed[:values][field["key"]]&.then { |value| format_computed_value(value) }
           else
             character_summary_value(field, character.sheet[field["key"]])
           end
    text.presence || "—"
  end

  # A long text keeps its line breaks; an empty one is left out of the sheet
  def summary_texts(character, fields)
    fields.filter_map do |field|
      text = character.sheet[field["key"]]
      [field["label"], text] if text.present?
    end
  end

  # A section of long texts left empty (notes) shows nothing, not even its subtitle
  def summary_section_empty?(character, fields)
    fields.all? { |field| summary_group(field) == :texts } && summary_texts(character, fields).empty?
  end

  # The values the table gives (the level), shown with the facts of the first block
  def summary_table_fields(character)
    character.sheet_fields.select { |field| field["from_table"] }
  end

  def summary_proficient?(character, field)
    character.sheet[field["key"]] == true
  end

  # A yes-or-no value as yes or no; a resource by its maximum; a number with the separator of the language (10,5)
  def character_summary_value(field, value)
    case field["type"]
    when "boolean" then t(value ? "answer_yes" : "answer_no", scope: "game_tables.character_steps.summary")
    when "picks" then (field["granted"].to_a + Array(value)).to_sentence
    when "resource" then value.is_a?(Hash) ? number_with_delimiter(value["max"]) : nil
    when "number", "ability", "experience" then value.nil? ? nil : number_with_delimiter(value)
    else value
    end
  end
end
