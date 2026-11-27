require "zlib"

# Where the fields of a character sheet go (the fields themselves: CharacterSheets::FieldsHelper). Decision: **each
# field type has one look, the same wherever it is** (for the template builder: the game master picks a type and names
# it): an ability is a tile with its modifier, a number, a resource or a computed value is a box ("− value +", or the
# value large), a bonus is a tight row, a yes-or-no value is a "No | Yes" switch, a choice a list, a text a text area. A
# section only arranges them: side by side (flow), in two columns (fields marked column: aside on the right), abilities
# in a grid with the dice roll, bonuses in rows with their help said once
module CharacterSheets
  module LayoutHelper
    # A choice or a text fills its place: a cell of the grid of lists, or the whole width for a long text.
    # A box has its own width (154 px, character_sheets/fields/_stat)
    FIELD_WIDTH_CLASSES = { "text" => "w-full", "choice" => "w-full" }.freeze
    SHORT_TEXT_WIDTH_CLASSES = "w-full".freeze
    # The groups of a flow, in this order (decision): lists and short texts in a grid of equal widths, then the
    # boxes and tiles side by side, then the groups of check boxes (picks: the languages), then the long texts across
    # the width, then the switches, each on its line
    FLOW_GROUPS = %i[lists boxes picks texts attacks switches].freeze
    # How each group lays out its fields. The grid of lists follows the width of the section (container query):
    # one list per line, two from 384 px, three from 512 px, six from 1024 px
    FLOW_GROUP_CLASSES = {
      # Six per line from 1024 px of section: the short fields of the physical appearance on one line (Details step)
      lists: "grid gap-x-4 @sm:grid-cols-2 @lg:grid-cols-3 @5xl:grid-cols-6",
      boxes: "flex flex-wrap items-start gap-3",
      picks: "flex flex-col",
      # Two by two from 768 px of section (the four texts of the Details step: appearance and personality, then
      # backstory and features); four on one line made them too narrow
      # Their text areas 144 px high (decision: they fill the screen better than the 96 px of a single text area)
      texts: "grid gap-x-6 @3xl:grid-cols-2 [&_textarea]:min-h-36",
      attacks: "flex flex-col",
      switches: "flex flex-col gap-2"
    }.freeze

    # The fields by section ("Caractéristiques", "Compétences"...), in the order of the template
    def sheet_sections(fields)
      fields.group_by { |field| field["section"] }
    end

    # option_cards: a list with icons (the class) drawn as cards, the option picked explained beside them;
    # described_choices: lists whose options have a description (class, species, background), beside a summary of the
    # options picked; abilities: tiles in a grid, with the dice roll; rows: saving throws and skills, their help said
    # once; two_columns: a section with fields in its right column (column: aside, the personality); flow: anything else
    def sheet_section_layout(fields)
      return choices_section_layout(fields) if choices_section_layout(fields)
      return :abilities if abilities_section?(fields)
      return :rows if rows_section?(fields)
      return :two_columns if fields.any? { |field| sheet_field_aside?(field) }
      return :split if split_section?(fields)

      :flow
    end

    # The lists picked on the first pages: as cards when they have icons, beside their summary when they are described
    def choices_section_layout(fields)
      return :option_cards if fields.first&.dig("icons")

      :described_choices if fields.any? { |field| field["descriptions"] }
    end

    # The abilities, with the bonus of the background placed on them (ability_bonuses) when the template has one
    def abilities_section?(fields)
      fields.any? { |field| field["type"] == "ability" } &&
        fields.all? { |field| %w[ability ability_bonuses].include?(field["type"]) }
    end

    def rows_section?(fields)
      fields.all? { |field| field["type"] == "bonus" }
    end

    # Picks (with or without lists) beside long texts, nothing else: two columns across the width, the choices on the
    # left, the texts on the right (in one flow, the texts stretched across the screen). Short fields alone with long
    # texts stay in the flow: a line of short fields, then the texts (the Details step, decision)
    def split_section?(fields)
      groups = fields.map { |field| sheet_flow_group(field) }
      groups.include?(:texts) && groups.include?(:picks) && (groups - %i[texts lists picks]).empty?
    end

    def sheet_field_aside?(field)
      field["column"] == "aside"
    end

    # The help of the rows of a section, said once under its title rather than under one of its rows
    def sheet_section_helps(fields)
      fields.filter_map { |field| field["help"] }.uniq
    end

    # Whether an option of a list of the sheet offers some of these fields to pick (skill_choices of its effects)
    def sheet_offered_by_a_choice?(fields, all_fields)
      offered_keys = all_fields.flat_map do |field|
        field["effects"].to_h.values.flat_map { |effects| effects.dig("skill_choices", "from").to_a }
      end
      fields.any? { |field| offered_keys.include?(field["key"]) }
    end

    # Whether the table of the character limits the skills to what its class offers (step Settings)
    def skill_choices_limited?(character)
      character.try(:game_table)&.limit_skill_choices
    end

    # The messages the server gave about these rows (CharacterSkillChoicesValidator), each said once
    # What gives a saving throw or a skill without picking it (the class, the background, a feat), written on its line:
    # it counts in none of the skills to pick (decision of 27 November: a box ticked with no word puzzled the player)
    def sheet_given_by(character, field)
      return unless character.is_a?(Character) && character.pc?

      @sheet_given_by ||= {}
      @sheet_given_by[character.id] ||= character.skill_choices.given_by.merge(character.feat_skill_sources)
      @sheet_given_by[character.id][field["key"]]
    end

    def sheet_rows_errors(character, fields)
      fields.flat_map { |field| character.errors[:"sheet.#{field['key']}"] }.uniq
    end

    # The fields of a flow section by group (FLOW_GROUPS), each group in the order of the template, empty groups left
    # out: [[:lists, [class, species, alignment]], [:boxes, [level]]]
    def sheet_flow_groups(fields)
      grouped_fields = fields.group_by { |field| sheet_flow_group(field) }
      FLOW_GROUPS.filter_map { |group| [group, grouped_fields[group]] if grouped_fields[group] }
    end

    # The groups of a flow by line: the lists and the picks share one (the alignment beside the languages, decision:
    # each on its line left too much empty space); every other group has its own
    def sheet_flow_rows(fields)
      sheet_flow_groups(fields).slice_when { |before, after| !(before.first == :lists && after.first == :picks) }.to_a
    end

    # The name of the character (lead) opens the column of the lists when the picks stand beside them (the
    # languages): both columns start at the same height (decision). Otherwise the section puts it above its fields
    def sheet_lead_in_lists_column?(fields)
      sheet_section_layout(fields) == :flow && sheet_flow_rows(fields).any? { |row| row.size > 1 }
    end

    def sheet_flow_group_classes(group)
      FLOW_GROUP_CLASSES.fetch(group)
    end

    def sheet_flow_group(field)
      FieldTypes.of(field).flow_group(field)
    end

    def sheet_field_width_classes(field)
      return SHORT_TEXT_WIDTH_CLASSES if field["type"] == "text" && field["short"]

      FIELD_WIDTH_CLASSES.fetch(field["type"], "w-full")
    end

    # A field in a box keeps its help out of it: the helps go under the row of its section, across the width
    def sheet_field_narrow?(field)
      FieldTypes.of(field).boxed?
    end

    # The helps of the boxed fields of a section, under its row. Fields with the same help share one note
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
end
