# Works out the values of a character sheet that the player does not type, by the rules the template picked from
# closed lists (SheetTemplate::MODIFIER_RULES and COMPUTED_RULES, never a formula): the modifier of an ability,
# the proficiency bonus of the level typed (level_from, level_thresholds), the modifier behind the initiative,
# and the bonuses of the saving throws and skills (ability modifier, plus the proficiency when ticked).
# Nothing here is stored: the sheet keeps what the player typed, so a computed value is never out of date.
# character_sheet_controller.js works them out the same way while the player types: changing one means changing both
class CharacterSheetCalculator
  def initialize(fields:, sheet:, level_thresholds:)
    @fields = fields
    @sheet = sheet.to_h
    @level_thresholds = level_thresholds.to_a.sort_by { |threshold| threshold["level"] }
  end

  # scores: by ability key, the score raised by the bonus of the background (ability_bonuses), nil until typed;
  # modifiers: worked out from those scores; values: the computed and bonus fields, by key
  def call
    scores = ability_scores
    modifiers = ability_modifiers(scores)
    computed_values = computed_field_values(modifiers)
    { scores: scores, modifiers: modifiers, values: computed_values.merge(bonus_values(modifiers, computed_values)) }
  end

  # The modifier of a score by the rule of its ability. half_above_ten: (score - 10) / 2, rounded down: 14 gives +2,
  # 9 gives -1. nil without a score, or for a rule the app does not know
  def self.modifier(score, rule)
    return unless score.is_a?(Integer)

    (score - 10).div(2) if rule == "half_above_ten"
  end

  private

  def ability_fields
    @fields.select { |field| field["type"] == "ability" }
  end

  # The score typed, plus the bonus placed on it (the bonus is kept apart, decision)
  def ability_scores
    ability_fields.to_h do |field|
      score = @sheet[field["key"]]
      [field["key"], score.is_a?(Integer) ? score + ability_bonuses[field["key"]].to_i : nil]
    end
  end

  def ability_bonuses
    @ability_bonuses ||= begin
      bonus_field = @fields.find { |field| field["type"] == "ability_bonuses" }
      bonus_field ? @sheet[bonus_field["key"]].to_h : {}
    end
  end

  def ability_modifiers(scores)
    ability_fields.to_h { |field| [field["key"], self.class.modifier(scores[field["key"]], field["modifier"])] }
  end

  def computed_field_values(modifiers)
    @fields.select { |field| field["type"] == "computed" }
           .to_h { |field| [field["key"], computed_value(field, modifiers)] }
  end

  def computed_value(field, modifiers)
    case field["rule"]
    when "proficiency_by_level" then threshold_of_level(field["level_from"])&.dig("proficiency_bonus")
    when "ability_modifier" then modifiers[field["based_on"]]
    when "hit_dice_by_class" then hit_dice(field)
    when "spell_save_dc" then spell_attack(field, modifiers)&.then { |attack| (8 + attack).to_s }
    when "spell_attack_bonus" then spell_attack(field, modifiers)
    when "hit_points_by_level" then hit_points(field, modifiers)&.to_s
    when "unarmored_armor_class" then unarmored_armor_class(field, modifiers)&.to_s
    when "starting_gold" then StartingEquipment.gold_from(fields: @fields, sheet: @sheet)&.to_s
    end
  end

  # Level 1: the highest roll of the die, then its average (half plus one) at each level, the modifier added each time.
  # A plain number, kept as a text like the hit dice ("8", not "+8"). nil until the class and the ability are known
  def hit_points(field, modifiers)
    sides = class_effects(field)["hit_die"]
    modifier = modifiers[field["based_on"]]
    return unless sides && modifier

    sides + modifier + ((typed_level(field["level_from"]) - 1) * ((sides / 2) + 1 + modifier))
  end

  # 10 + the modifier of based_on, + the modifier of the ability of the unarmored defense of the class (barbarian,
  # monk). nil until based_on has a score
  def unarmored_armor_class(field, modifiers)
    modifier = modifiers[field["based_on"]]
    return unless modifier

    10 + modifier + modifiers[class_effects(field)["unarmored_defense"]].to_i
  end

  # "3d8": one die per level, its sides the hit_die of the class chosen. nil until a class of the list is chosen
  def hit_dice(field)
    sides = class_effects(field)["hit_die"]
    "#{typed_level(field['level_from'])}d#{sides}" if sides
  end

  # The proficiency plus the modifier of the spellcasting ability of the class chosen. nil for a class without spells,
  # or until that ability has a score. The save DC is a plain number: a text, like the hit dice ("13", not "+13")
  def spell_attack(field, modifiers)
    modifier = modifiers[class_effects(field).dig("spellcasting", "ability")]
    modifier + proficiency_of(field) if modifier
  end

  def proficiency_of(field)
    proficiency_field = @fields.find { |candidate| candidate["key"] == field["proficiency"] }
    proficiency_field ? computed_value(proficiency_field, {}).to_i : 0
  end

  # The effects of the option chosen in the list class_from ({} before a choice)
  def class_effects(field)
    class_field = @fields.find { |candidate| candidate["key"] == field["class_from"] }
    class_field&.dig("effects", @sheet[field["class_from"]].to_s) || {}
  end

  # nil while the ability has no score: a bonus cannot be worked out yet
  def bonus_values(modifiers, computed_values)
    @fields.select { |field| field["type"] == "bonus" }.to_h do |field|
      modifier = modifiers[field["based_on"]]
      proficiency = @sheet[field["key"]] == true ? computed_values[field["proficiency"]].to_i : 0
      [field["key"], modifier && (modifier + proficiency)]
    end
  end

  # The threshold of the level typed: the last one at or under it
  def threshold_of_level(level_key)
    level = typed_level(level_key)
    @level_thresholds.reverse.find { |threshold| level >= threshold["level"] }
  end

  # No level typed counts as level 1
  def typed_level(level_key)
    @sheet[level_key].is_a?(Integer) ? @sheet[level_key] : 1
  end
end
