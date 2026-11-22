module ChoiceEffects
  # The spells of a class: its ability, then its tables, one number per level from 1 to 20, which the groups of spells
  # of the template read (character_fields.spell_groups: count_from, max_level_from; heroic fantasy: cantrips,
  # prepared, max_spell_level), and its own rules the groups may read (changes_from: prepared_changes). Read by
  # CharacterSheets::SpellChoices; that each table a group names is there is checked by SheetTemplates::SpellGroupsCheck
  class Spellcasting < Base
    KEY = "spellcasting".freeze
    TARGET_TYPE = "ability".freeze
    LEVELS = 20

    def target_keys(value)
      [value.to_h["ability"].to_s]
    end

    # Every table (a list) gives one number per level
    def value_errors(value, **)
      value.to_h.select { |_name, table| table.is_a?(Array) }
           .reject { |_name, table| level_table?(table) }
           .map { |name, _table| [:invalid_level_table, { table: name }] }
    end

    def facts(value, fields_by_key)
      ability = fields_by_key.dig(value.to_h["ability"], "label")
      ability ? [[fact_label(:spellcasting), ability]] : []
    end

    # The number of a table at a level (1 to 20), 0 without the table
    def self.level_table?(table)
      table.is_a?(Array) && table.size == LEVELS && table.all?(Integer)
    end

    private

    def level_table?(table)
      self.class.level_table?(table)
    end
  end
end
