module SheetTemplates
  # The groups of spells of the template (character_fields.spell_groups, CharacterSheets::SpellChoices), when it
  # declares them: a key in snake_case used once, a label, only the settings a group knows, its levels and the table of
  # its count, a known change rule; and every class that casts spells (spellcasting) has the tables the groups name,
  # one number per level, and a known rule where a group reads it (changes_from)
  class SpellGroupsCheck < Check
    PARAMETERS = %w[key label help min_level max_level max_level_from count_from changes changes_from].freeze
    REQUIRED_PARAMETERS = %w[key label min_level count_from].freeze

    def call
      groups = @sheet_template.character_fields.to_h["spell_groups"].to_a
      return [] if groups.empty?

      duplicate_errors(groups) + groups.flat_map { |group| group_errors(group) } +
        groups.flat_map { |group| class_errors(group) }
    end

    private

    def duplicate_errors(groups)
      groups.pluck("key").tally.select { |_key, count| count > 1 }.keys
            .map { |key| [:duplicate_spell_group, { group: key }] }
    end

    def group_errors(group)
      name = group["label"].presence || group["key"].to_s
      name_errors(group, name) + parameter_errors(group, name) + changes_errors(group, name)
    end

    def name_errors(group, name)
      errors = []
      errors << [:invalid_spell_group_key, { group: name, key: group["key"].to_s }] unless valid_key?(group["key"])
      unless valid_label?(group["label"])
        errors << [:invalid_spell_group_label, { group: name, count: LABEL_MAX_LENGTH }]
      end
      errors
    end

    # Its known settings, those it needs, and its highest level: fixed (max_level) or a table of the class
    def parameter_errors(group, name)
      unknown = (group.keys - PARAMETERS).map do |parameter|
        [:unknown_spell_group_parameter, { group: name, parameter: parameter }]
      end
      missing = REQUIRED_PARAMETERS.reject { |parameter| group[parameter].present? || group[parameter].is_a?(Integer) }
      missing << "max_level" unless group.key?("max_level") || group.key?("max_level_from")
      unknown + missing.map { |parameter| [:missing_spell_group_parameter, { group: name, parameter: parameter }] }
    end

    def changes_errors(group, name)
      changes = group["changes"]
      return [] if changes.nil? || CharacterSheets::SpellChoices::PREPARED_CHANGES.include?(changes)

      [[:unknown_spell_group_changes, { group: name, changes: changes }]]
    end

    # Each class that casts spells gives the tables the group reads, and a known rule where it reads one
    def class_errors(group)
      spellcasting_options.flat_map do |place, spellcasting|
        table_errors(group, place, spellcasting) + class_changes_errors(group, place, spellcasting)
      end
    end

    def table_errors(group, place, spellcasting)
      group.values_at("count_from", "max_level_from").compact.reject { |table| spellcasting.key?(table) }
           .map { |table| [:missing_spell_table, place.merge(table: table, group: group["label"].to_s)] }
    end

    def class_changes_errors(group, place, spellcasting)
      changes = spellcasting[group["changes_from"]]
      return [] if group["changes_from"].nil? || changes.nil?
      return [] if CharacterSheets::SpellChoices::PREPARED_CHANGES.include?(changes)

      [[:unknown_effect_value, place.merge(effect: group["changes_from"], value: changes)]]
    end

    # [where, spellcasting] for each option of a list of the sheet whose effects cast spells (the classes)
    def spellcasting_options
      @spellcasting_options ||= character_fields.select { |field| field["effects"] }.flat_map do |field|
        field["effects"].filter_map do |option, effects|
          spellcasting = effects.to_h["spellcasting"]
          [context("character_fields", field).merge(option: option), spellcasting.to_h] if spellcasting
        end
      end
    end
  end
end
