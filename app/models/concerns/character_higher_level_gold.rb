# The gold a player's character created above level 1 gets more (the tier of its level,
# CharacterHigherLevelEquipment): a fixed part, and a part rolled by the server once, when its creation is done, added
# to the gold its starting equipment gives. Part of CharacterHigherLevelEquipment
module CharacterHigherLevelGold
  extend ActiveSupport::Concern

  # The gold its tier adds: its fixed part, then its roll (rolled here, once, when the creation is done)
  def higher_level_gold(random: Random)
    tier = higher_level_equipment_tier.to_h
    roll = tier["gold_roll"]
    rolled = roll ? Array.new(roll["dice"]) { random.rand(1..roll["sides"]) }.sum * roll["multiplier"] : 0
    tier["gold"].to_i + rolled
  end

  # Its gold, once its starting gold is written (Character#complete_creation), raised by the gold of its tier
  def add_higher_level_gold(random: Random)
    amount = higher_level_gold(random: random)
    key = starting_gold_field_key
    self.sheet = sheet.merge(key => sheet[key].to_i + amount) if key && amount.positive?
  end

  private

  # The field that starts with the starting gold (its initial_from, a value of the rule starting_gold)
  def starting_gold_field_key
    rule_keys = sheet_fields.select { |field| field["rule"] == ComputedRules::StartingGold::KEY }.pluck("key")
    sheet_fields.find { |field| rule_keys.include?(field["initial_from"]) }&.dig("key")
  end
end
