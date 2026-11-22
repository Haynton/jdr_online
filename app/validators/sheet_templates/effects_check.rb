module SheetTemplates
  # The effects of the options of the lists of the character sheet (SheetTemplate::CHOICE_EFFECTS): known effects, and
  # each one naming fields of the right type (proficient: bonuses, ability_bonus_choices: abilities...), a spellcasting
  # given level by level, starting equipment options that can be read (CharacterSheets::StartingEquipment)
  class EffectsCheck < Check
    SPELLCASTING_TABLES = %w[cantrips prepared max_spell_level].freeze
    LEVELS = 20

    def call
      character_fields.select { |field| field["effects"] }.flat_map do |field|
        field["effects"].flat_map do |option, effects|
          effects_errors(effects.to_h, context("character_fields", field).merge(option: option))
        end
      end
    end

    private

    def effects_errors(effects, place)
      unknown = (effects.keys - SheetTemplate::CHOICE_EFFECTS).map { |effect| [:unknown_effect, place.merge(effect: effect)] }
      unknown + target_errors(effects, place) + spellcasting_errors(effects["spellcasting"], place) +
        equipment_errors(effects["starting_equipment"], place)
    end

    # The fields an effect names, by the type they must have
    def target_errors(effects, place)
      targets = { "proficient" => [effects["proficient"], "bonus"],
                  "skill_choices" => [effects.dig("skill_choices", "from"), "bonus"],
                  "ability_bonus_choices" => [effects["ability_bonus_choices"], "ability"] }
      errors = targets.flat_map { |effect, (keys, type)| wrong_targets(effect, keys, type, place) }
      unknown_set = effects["set"].to_h.keys - character_fields.pluck("key")
      errors + unknown_set.map { |key| [:unknown_effect_target, place.merge(effect: "set", target: key)] }
    end

    def wrong_targets(effect, keys, type, place)
      (keys.to_a - keys_of_type(character_fields, type)).map do |key|
        [:wrong_effect_target, place.merge(effect: effect, target: key, expected: type_name(type))]
      end
    end

    # The ability of its spells, and for each table one number per level, from 1 to 20
    def spellcasting_errors(spellcasting, place)
      return [] unless spellcasting

      table_errors = SPELLCASTING_TABLES.reject { |table| valid_level_table?(spellcasting[table]) }
                                        .map { |table| [:invalid_level_table, place.merge(table: table)] }
      spellcasting_ability_errors(spellcasting, place) + table_errors + prepared_changes_errors(spellcasting, place)
    end

    def spellcasting_ability_errors(spellcasting, place)
      ability = spellcasting["ability"].to_s
      return [] if keys_of_type(character_fields, "ability").include?(ability)

      [[:wrong_effect_target, place.merge(effect: "spellcasting", target: ability, expected: type_name("ability"))]]
    end

    def valid_level_table?(values)
      values.is_a?(Array) && values.size == LEVELS && values.all?(Integer)
    end

    def prepared_changes_errors(spellcasting, place)
      changes = spellcasting["prepared_changes"]
      return [] if changes.nil? || CharacterSheets::SpellChoices::PREPARED_CHANGES.include?(changes)

      [[:unknown_effect_value, place.merge(effect: "prepared_changes", value: changes)]]
    end

    # One letter per option, each line an item (key) or a choice (choose) among groups of the item sheet
    def equipment_errors(starting_equipment, place)
      return [] unless starting_equipment

      options = starting_equipment["options"].to_a
      letters = options.pluck("key")
      errors = letters.tally.select { |_letter, count| count > 1 }.keys.map do |letter|
        [:duplicate_equipment_option, place.merge(letter: letter.to_s.upcase)]
      end
      errors + options.flat_map { |option| equipment_line_errors(option, place) }
    end

    def equipment_line_errors(option, place)
      option["items"].to_a.flat_map do |line|
        next [[:invalid_equipment_line, place.merge(letter: option["key"].to_s.upcase)]] unless item_or_choice?(line)

        (line["choose"].to_a - item_groups).map { |group| [:unknown_item_group, place.merge(group: group)] }
      end
    end

    # A line is an item (key) or a choice among groups (choose), never both nor none
    def item_or_choice?(line)
      line["key"].present? ^ line["choose"].present?
    end

    def item_groups
      fields_of("item_fields").find { |field| field["key"] == "group" }&.dig("options").to_a
    end
  end
end
