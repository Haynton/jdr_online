module HigherLevelEquipmentMethods
  # By the tiers the template declares, each from a level ({ "from_level" => 5, "gold" => 500, "gold_roll" =>
  # { "dice" => 1, "sides" => 10, "multiplier" => 25 }, "magic_items" => { "common" => 1, "uncommon" => 1 } }): the
  # last tier a level reaches, nothing below the first. The gold is added at the end of the creation, rolled by the
  # server (CharacterHigherLevelEquipment); the magic items are picked at the step of the equipment
  class ByLevel < Base
    KEY = "by_level".freeze
    OWN_PARAMETERS = %w[tiers].freeze
    TIER_PARAMETERS = %w[from_level gold gold_roll magic_items].freeze
    ROLL_PARAMETERS = %w[dice sides multiplier].freeze

    def parameters
      COMMON_PARAMETERS + OWN_PARAMETERS
    end

    def required_parameters
      OWN_PARAMETERS
    end

    def tier_for(method, level)
      Array(method["tiers"]).select { |tier| tier["from_level"].to_i <= level }.max_by { |tier| tier["from_level"] }
    end

    def settings_errors(method, **)
      tiers = method["tiers"]
      return [] if tiers.is_a?(Array) && tiers.any? && tiers.all? { |tier| valid_tier?(tier) } && ascending?(tiers)

      [[:invalid_equipment_tiers, { method: method["label"] }]]
    end

    private

    def valid_tier?(tier)
      tier.is_a?(Hash) && (tier.keys - TIER_PARAMETERS).empty? && positive_integer?(tier["from_level"]) &&
        (tier["gold"].nil? || positive_integer?(tier["gold"])) && valid_roll?(tier["gold_roll"]) &&
        valid_magic_items?(tier["magic_items"])
    end

    def valid_roll?(roll)
      roll.nil? || (roll.is_a?(Hash) && roll.keys.sort == ROLL_PARAMETERS.sort &&
                    roll.values.all? { |value| positive_integer?(value) })
    end

    def valid_magic_items?(items)
      items.nil? || (items.is_a?(Hash) && items.all? do |rarity, count|
        rarity.is_a?(String) && positive_integer?(count)
      end)
    end

    def ascending?(tiers)
      levels = tiers.pluck("from_level")
      levels == levels.sort && levels.uniq.size == levels.size
    end

    def positive_integer?(value)
      value.is_a?(Integer) && value.positive?
    end
  end
end
