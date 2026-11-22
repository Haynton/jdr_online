# Checks the values of a player character sheet against the fields of the template copied into its table:
# JSONB has no check of its own in the database. A wrong value gets its error on "sheet.<key of the field>",
# shown under that field of the form. Only the player characters for now (NPCs and monsters: P4)
class CharacterSheetValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && character.game_table

    fields_by_key = character.sheet_fields.index_by { |field| field["key"] }
    character.sheet.each do |key, value|
      next if fields_by_key.dig(key, "type") == "ability_bonuses"

      error_type, error_options = value_error(character, fields_by_key[key], value)
      character.errors.add(:"sheet.#{key}", error_type, **error_options.to_h) if error_type
    end
    validate_required_fields(character)
    validate_ability_bonuses(character)
  end

  private

  # The bonus of the background reads the other values of the sheet: the option picked, the scores
  def validate_ability_bonuses(character)
    character.sheet_fields.select { |field| field["type"] == "ability_bonuses" }.each do |field|
      error_type, error_options = ability_bonuses_error(character, field)
      character.errors.add(:"sheet.#{field['key']}", error_type, **error_options.to_h) if error_type
    end
  end

  # Only the abilities the option picked raises, spread as +2 and +1 or +1 to each (or a part of it, while the player
  # places them), and no score past the maximum of its ability once raised
  def ability_bonuses_error(character, field)
    bonuses = character.sheet[field["key"]]
    return if bonuses.nil?
    return [:invalid] unless bonus_spread_allowed?(bonuses, raised_abilities(character, field))

    raised_too_high = bonuses.keys.find do |ability_key|
      raised_score(character, ability_key, bonuses) > ability_maximum(character, ability_key)
    end
    [:ability_bonus_too_high, { count: ability_maximum(character, raised_too_high) }] if raised_too_high
  end

  def bonus_spread_allowed?(bonuses, raised_abilities)
    return false unless bonuses.is_a?(Hash) && (bonuses.keys - raised_abilities).empty?
    return false unless bonuses.values.all? { |bonus| [1, 2].include?(bonus) }

    bonuses.values.sum <= 3 && bonuses.values.count(2) <= 1
  end

  # The abilities that the option picked in the list named by from raises (ability_bonus_choices of its effects)
  def raised_abilities(character, field)
    list = character.sheet_fields.find { |candidate| candidate["key"] == field["from"] }
    list&.dig("effects", character.sheet[field["from"]].to_s, "ability_bonus_choices").to_a
  end

  def raised_score(character, ability_key, bonuses)
    character.sheet[ability_key].to_i + bonuses[ability_key]
  end

  def ability_maximum(character, ability_key)
    character.sheet_fields.find { |field| field["key"] == ability_key }&.dig("max") || Float::INFINITY
  end

  # The fields marked required in the step being saved (Character#fill_step): the step stays until they are filled
  def validate_required_fields(character)
    character.required_sheet_fields.to_a.each do |field|
      character.errors.add(:"sheet.#{field['key']}", :blank) if character.sheet[field["key"]].blank?
    end
  end

  # The starting equipment depends on the options picked elsewhere on the sheet (CharacterSheets::StartingEquipment)
  def value_error(character, field, value)
    starting_equipment = CharacterSheets::StartingEquipment
    return starting_equipment.new(character).error_for(field, value) if field&.dig("type") == "equipment_option"

    FieldValueChecker.error_for(field, value)
  end
end
