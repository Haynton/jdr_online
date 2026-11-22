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

  # modifiers: by ability key (nil until a score is typed); values: the computed and bonus fields, by key
  def call
    modifiers = ability_modifiers
    computed_values = computed_field_values(modifiers)
    { modifiers: modifiers, values: computed_values.merge(bonus_values(modifiers, computed_values)) }
  end

  # The modifier of a score by the rule of its ability. half_above_ten: (score - 10) / 2, rounded down: 14 gives +2,
  # 9 gives -1. nil without a score, or for a rule the app does not know
  def self.modifier(score, rule)
    return unless score.is_a?(Integer)

    (score - 10).div(2) if rule == "half_above_ten"
  end

  private

  def ability_modifiers
    @fields.select { |field| field["type"] == "ability" }
           .to_h { |field| [field["key"], self.class.modifier(@sheet[field["key"]], field["modifier"])] }
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
    end
  end

  # "3d8": one die per level, its sides by the class. nil until a class of the list is chosen
  def hit_dice(field)
    sides = field["dice_by_class"].to_h[@sheet[field["class_from"]]]
    "#{typed_level(field['level_from'])}d#{sides}" if sides
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
