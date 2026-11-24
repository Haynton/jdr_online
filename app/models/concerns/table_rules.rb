# The rules of the game the game master picks for a table (game_tables.rules), among the ways its template offers to
# play them: the way to get the scores of the abilities (AbilityMethods, character_fields.ability_methods) and the way
# to get the hit points of the levels after the first (HitPointMethods, character_fields.hit_point_methods), the
# starting equipment (StartingEquipmentMethods, character_fields.starting_equipment_methods). For each one, a way of
# the template, or the player's choice (decision: the game master may leave it to each player) where it has one
module TableRules
  extend ActiveSupport::Concern

  # Leaves the way to each player, while making their character
  PLAYER_CHOICE = "player_choice".freeze
  # Each rule (its key in game_tables.rules) and the list of its ways in the template
  RULE_METHODS = { "ability_method" => "ability_methods", "hit_point_method" => "hit_point_methods",
                   "starting_equipment_method" => "starting_equipment_methods" }.freeze
  # The rules the game master may leave to the player. Not the starting equipment: its first way already lets the
  # player pick items or gold
  RULES_WITH_PLAYER_CHOICE = %w[ability_method hit_point_method].freeze

  included do
    validate :rule_methods_offered_by_template
  end

  # The ways the template of the table offers for that rule, as it declares them ({ "type", "label", "help", and their
  # settings })
  def rule_methods(rule)
    template_snapshot.to_h.dig("character_fields", RULE_METHODS.fetch(rule)).to_a
  end

  # The type picked by the game master, or player_choice; the first way of the template while nothing is picked
  def rule_choice(rule)
    rules.to_h[rule].presence || rule_methods(rule).first&.dig("type")
  end

  def players_choose?(rule)
    rule_choice(rule) == PLAYER_CHOICE
  end

  # The way of that type, as the template declares it, or nil
  def rule_method_of(rule, type)
    rule_methods(rule).find { |method| method["type"] == type }
  end

  # Set from the step Settings: a type the template offers, or player_choice (checked by the validation)
  def pick_rule_method(rule, type)
    self.rules = rules.to_h.merge(rule => type.presence).compact
  end

  # The scores of the abilities. A table made before the ways keeps its dice roll (character_fields.ability_roll), as
  # the only way
  def ability_methods
    return [] if ability_fields.empty?

    rule_methods("ability_method").presence ||
      former_ability_roll(template_snapshot.to_h.dig("character_fields", "ability_roll"))
  end

  def ability_method_choice
    rules.to_h["ability_method"].presence || ability_methods.first&.dig("type")
  end

  def ability_method_choice=(type)
    pick_rule_method("ability_method", type)
  end

  def players_choose_ability_method?
    ability_method_choice == PLAYER_CHOICE
  end

  def ability_method_of(type)
    ability_methods.find { |method| method["type"] == type }
  end

  # How the dice are rolled ({ "dice" => 4, "sides" => 6, "keep_highest" => 3 }), nil when the template offers no roll
  def ability_roll_method
    ability_method_of(AbilityMethods::Roll::KEY)
  end

  # The hit points of the levels after the first
  def hit_point_method_choice
    rule_choice("hit_point_method")
  end

  def hit_point_method_choice=(type)
    pick_rule_method("hit_point_method", type)
  end

  # The starting equipment
  def starting_equipment_method_choice
    rule_choice("starting_equipment_method")
  end

  def starting_equipment_method_choice=(type)
    pick_rule_method("starting_equipment_method", type)
  end

  private

  def former_ability_roll(ability_roll)
    return [] unless ability_roll

    [ability_roll.merge("type" => AbilityMethods::Roll::KEY, "label" => I18n.t("game_tables.rules.former_roll"))]
  end

  def rule_methods_offered_by_template
    RULE_METHODS.each_key do |rule|
      chosen = rules.to_h[rule]
      next if chosen.blank? || offered_choice?(rule, chosen)

      errors.add(:"#{rule}_choice", :inclusion)
    end
  end

  def offered_choice?(rule, chosen)
    return RULES_WITH_PLAYER_CHOICE.include?(rule) if chosen == PLAYER_CHOICE

    methods = rule == "ability_method" ? ability_methods : rule_methods(rule)
    methods.any? { |method| method["type"] == chosen }
  end
end
