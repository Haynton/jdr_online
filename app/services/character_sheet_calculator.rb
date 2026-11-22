# Works out the values of a character sheet that the player does not type, by the rules the template picked from
# a closed list (SheetTemplate::COMPUTED_RULES, never a formula): the modifier of an ability (has_modifier),
# the level reached (experience and level_thresholds), the proficiency bonus of that level (computed fields),
# and the bonuses of the saving throws and skills (ability modifier, plus the proficiency when ticked).
# Nothing here is stored: the sheet keeps what the player typed, so a computed value is never out of date.
# character_sheet_controller.js works them out the same way while the player types: changing one means changing both
class CharacterSheetCalculator
  def initialize(fields:, sheet:, level_thresholds:)
    @fields = fields
    @sheet = sheet.to_h
    @level_thresholds = level_thresholds.to_a.sort_by { |threshold| threshold["experience"] }
  end

  # level: the level reached (nil without thresholds); modifiers: by ability key (nil until a score is typed);
  # values: the computed and bonus fields, by key
  def call
    modifiers = ability_modifiers
    computed_values = computed_field_values
    { level: reached_threshold&.dig("level"), modifiers: modifiers,
      values: computed_values.merge(bonus_values(modifiers, computed_values)) }
  end

  # (score - 10) / 2, rounded down: 14 gives +2, 9 gives -1
  def self.modifier(score)
    (score - 10).div(2) if score.is_a?(Integer)
  end

  private

  def ability_modifiers
    @fields.select { |field| field["has_modifier"] }
           .to_h { |field| [field["key"], self.class.modifier(@sheet[field["key"]])] }
  end

  def computed_field_values
    @fields.select { |field| field["type"] == "computed" }
           .to_h { |field| [field["key"], computed_value(field["rule"])] }
  end

  def computed_value(rule)
    case rule
    when "proficiency_by_level" then reached_threshold&.dig("proficiency_bonus")
    end
  end

  # nil while the ability has no score: a bonus cannot be worked out yet
  def bonus_values(modifiers, computed_values)
    @fields.select { |field| field["type"] == "bonus" }.to_h do |field|
      modifier = modifiers[field["based_on"]]
      proficiency = @sheet[field["key"]] == true ? computed_values[field["proficiency"]].to_i : 0
      [field["key"], modifier && (modifier + proficiency)]
    end
  end

  # The last threshold the experience has reached; no experience typed counts as 0
  def reached_threshold
    experience = @sheet[experience_key].is_a?(Integer) ? @sheet[experience_key] : 0
    @level_thresholds.reverse.find { |threshold| experience >= threshold["experience"] }
  end

  def experience_key
    @fields.find { |field| field["type"] == "experience" }&.dig("key")
  end
end
