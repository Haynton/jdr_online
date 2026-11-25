# The summary of the creation of a character, laid out like a character sheet (character_sheets/summary/_sheet,
# decision: a list of values was hard to read). Each step is a block of the sheet, with "Change" to go back to it; in
# a block, the fields are read-only and grouped by type, one look per type as on the steps: facts (lists, short texts,
# yes or no), ability tiles, boxes (numbers, resources, worked out values), rows (saving throws, skills), long texts.
# Read from any template: the heroic fantasy gives a sheet with its abilities across the width and three columns
module CharacterSheets
  module SummaryHelper
    SUMMARY_GROUPS = %i[facts tiles boxes rows texts].freeze
    # The partial of each group, written in full: a search for a partial finds who draws it
    SUMMARY_GROUP_PARTIALS = {
      facts: "character_sheets/summary/facts",
      tiles: "character_sheets/summary/tiles",
      boxes: "character_sheets/summary/boxes",
      rows: "character_sheets/summary/rows",
      texts: "character_sheets/summary/texts"
    }.freeze

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
    def summary_groups(fields, sheet)
      # The bonus of the background is in the scores, the equipment in its own list (summary_equipment), an internal
      # value (the starting gold, which fills the gold of the sheet) is shown nowhere, and a field the sheet does not
      # ask (the subclass, before level 3) neither
      shown_fields = fields.reject do |field|
        field["internal"] || summary_group(field).nil? || !FieldTypes.of(field).asked_on?(field, sheet)
      end
      grouped_fields = shown_fields.group_by { |field| summary_group(field) }
      SUMMARY_GROUPS.filter_map { |group| [group, grouped_fields[group]] if grouped_fields[group] }
    end

    # A value given by the table (the level) reads with the facts of the header, not in a box; any other field in the
    # group of its type (FieldTypes::Base#summary_group), nil when its type is not shown on the summary
    def summary_group(field)
      return :facts if field["from_table"]

      FieldTypes.of(field).summary_group(field)
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

    # The values of the game in the sections of a step, not asked at creation (the gold of the equipment), shown once
    # the character is complete: they start from what was worked out then (initial_from)
    def summary_play_fields(character, step)
      sections = step.fields.pluck("section").uniq
      character.sheet_fields.select do |field|
        field["at_creation"] == false && sections.include?(field["section"]) && !character.sheet[field["key"]].nil?
      end
    end

    # The values the table gives (the level), shown with the facts of the first block, unless a step shows them
    # already: a level the players choose is a field of the first page (CharacterCreationSteps
    # #with_fields_chosen_by_players)
    def summary_table_fields(character)
      shown_keys = character.creation_steps.summary_blocks.flat_map(&:field_keys)
      character.sheet_fields.select { |field| field["from_table"] && shown_keys.exclude?(field["key"]) }
    end

    def summary_proficient?(character, field)
      character.sheet[field["key"]] == true
    end

    # The value as read on the sheet, said by its type (a yes-or-no value as yes or no, a resource by its maximum, a
    # number with the separator of the language: FieldTypes::Base#summary_text)
    def character_summary_value(field, value)
      FieldTypes.of(field).summary_text(value, field)
    end

    def summary_group_partial(group)
      SUMMARY_GROUP_PARTIALS.fetch(group)
    end
  end
end
