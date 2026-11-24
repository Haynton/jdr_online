# The rules of the game the game master picks for a table (game_tables.rules), among the ways its template offers to
# play them. For now the way to get the scores of the abilities (AbilityMethods): one of those the template lists
# (character_fields.ability_methods), or the player's choice (decision: the game master may leave it to each player)
module TableRules
  extend ActiveSupport::Concern

  # Leaves the method of the scores to each player, on the abilities step of their character
  PLAYER_CHOICE = "player_choice".freeze

  included do
    validate :ability_method_offered_by_template
  end

  # The ways the template of the table offers, as it declares them ({ "type", "label", "help", and their settings }).
  # A table made before them keeps its dice roll (character_fields.ability_roll), as the only way
  def ability_methods
    return [] if ability_fields.empty?

    character_fields = template_snapshot.to_h["character_fields"].to_h
    character_fields["ability_methods"].presence || former_ability_roll(character_fields["ability_roll"])
  end

  # The type picked by the game master, or player_choice; the first way of the template while nothing is picked
  def ability_method_choice
    rules.to_h["ability_method"].presence || ability_methods.first&.dig("type")
  end

  # Set from the step Settings: a type the template offers, or player_choice (checked by the validation)
  def ability_method_choice=(type)
    self.rules = rules.to_h.merge("ability_method" => type.presence).compact
  end

  def players_choose_ability_method?
    ability_method_choice == PLAYER_CHOICE
  end

  # The way of that type, as the template declares it, or nil
  def ability_method_of(type)
    ability_methods.find { |method| method["type"] == type }
  end

  # How the dice are rolled ({ "dice" => 4, "sides" => 6, "keep_highest" => 3 }), nil when the template offers no roll
  def ability_roll_method
    ability_method_of(AbilityMethods::Roll::KEY)
  end

  private

  def former_ability_roll(ability_roll)
    return [] unless ability_roll

    [ability_roll.merge("type" => AbilityMethods::Roll::KEY, "label" => I18n.t("game_tables.rules.former_roll"))]
  end

  def ability_method_offered_by_template
    chosen = rules.to_h["ability_method"]
    return if chosen.blank? || chosen == PLAYER_CHOICE || ability_method_of(chosen)

    errors.add(:ability_method_choice, :inclusion)
  end
end
