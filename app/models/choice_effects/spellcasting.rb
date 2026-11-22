module ChoiceEffects
  # The spells of a class: its ability, then by level from 1 to 20 the cantrips, the prepared spells and the highest
  # spell level, and how its prepared spells change in the game (CharacterSheets::SpellChoices)
  class Spellcasting < Base
    KEY = "spellcasting".freeze
    TARGET_TYPE = "ability".freeze
    LEVEL_TABLES = %w[cantrips prepared max_spell_level].freeze
    LEVELS = 20

    def target_keys(value)
      [value.to_h["ability"].to_s]
    end

    def value_errors(value, **)
      spellcasting = value.to_h
      table_errors = LEVEL_TABLES.reject { |table| level_table?(spellcasting[table]) }
                                 .map { |table| [:invalid_level_table, { table: table }] }
      table_errors + prepared_changes_errors(spellcasting["prepared_changes"])
    end

    def facts(value, fields_by_key)
      ability = fields_by_key.dig(value.to_h["ability"], "label")
      ability ? [[fact_label(:spellcasting), ability]] : []
    end

    private

    # One number per level, from 1 to 20
    def level_table?(values)
      values.is_a?(Array) && values.size == LEVELS && values.all?(Integer)
    end

    def prepared_changes_errors(changes)
      return [] if changes.nil? || CharacterSheets::SpellChoices::PREPARED_CHANGES.include?(changes)

      [[:unknown_effect_value, { effect: "prepared_changes", value: changes }]]
    end
  end
end
