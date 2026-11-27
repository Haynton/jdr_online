module ChoiceEffects
  # The spells of a class: its ability, then its tables, one number per level from 1 to 20, which the groups of spells
  # of the template read (character_fields.spell_groups: count_from, max_level_from; heroic fantasy: cantrips,
  # prepared, max_spell_level), and its own rules the groups may read (changes_from: prepared_changes). Read by
  # CharacterSheets::SpellChoices; that each table a group names is there is checked by SheetTemplates::SpellGroupsCheck.
  # A table of lists gives, for each level, a number per level of spell: the spell slots (character_fields.spell_slots,
  # count_from; heroic fantasy: slots, [4, 3, 2] at level 5), read by CharacterSheets::SpellSlots and checked by
  # SheetTemplates::SpellSlotsCheck. A spellbook (the wizard: spellbook) holds the level 1+ spells the character knows,
  # start at creation and per_level more at each level gained, and the group prepares_from prepares among them
  # (CharacterSheets::Spellbook)
  class Spellcasting < Base
    KEY = "spellcasting".freeze
    TARGET_TYPE = "ability".freeze
    LEVELS = 20
    SPELLBOOK_PARAMETERS = %w[label help start per_level prepares_from copy_cost].freeze

    def target_keys(value)
      [value.to_h["ability"].to_s]
    end

    # Every table (a list) gives one number per level, or one list of numbers per level (the slots)
    def value_errors(value, **)
      tables = value.to_h.select { |_name, table| table.is_a?(Array) }
      slot_tables, number_tables = tables.partition { |_name, table| table.first.is_a?(Array) }
      number_tables.reject { |_name, table| level_table?(table) }
                   .map { |name, _table| [:invalid_level_table, { table: name }] } +
        slot_tables.reject { |_name, table| self.class.slot_table?(table) }
                   .map { |name, _table| [:invalid_slot_table, { table: name }] } +
        spellbook_errors(value.to_h["spellbook"])
    end

    def facts(value, fields_by_key)
      ability = fields_by_key.dig(value.to_h["ability"], "label")
      ability ? [[fact_label(:spellcasting), ability]] : []
    end

    # The number of a table at a level (1 to 20), 0 without the table
    def self.level_table?(table)
      table.is_a?(Array) && table.size == LEVELS && table.all?(Integer)
    end

    # One list per level, of whole numbers from 0 up: how many slots of each level of spell (the first for level 1)
    def self.slot_table?(table)
      table.is_a?(Array) && table.size == LEVELS &&
        table.all? { |counts| counts.is_a?(Array) && counts.all? { |count| count.is_a?(Integer) && !count.negative? } }
    end

    private

    def spellbook_errors(spellbook)
      return [] if spellbook.nil? || valid_spellbook?(spellbook)

      [[:invalid_spellbook, {}]]
    end

    def valid_spellbook?(spellbook)
      spellbook.is_a?(Hash) && (spellbook.keys - SPELLBOOK_PARAMETERS).empty? && spellbook["label"].present? &&
        [spellbook["start"], spellbook["per_level"]].all? { |count| count.is_a?(Integer) && !count.negative? } &&
        spellbook["prepares_from"].is_a?(String) && valid_copy_cost?(spellbook["copy_cost"])
    end

    # What copying a spell found costs, per level of the spell, in a coin of the sheet (currency: its key)
    def valid_copy_cost?(cost)
      cost.nil? || (cost.is_a?(Hash) && cost["per_level"].is_a?(Integer) && cost["currency"].is_a?(String))
    end

    def level_table?(table)
      self.class.level_table?(table)
    end
  end
end
