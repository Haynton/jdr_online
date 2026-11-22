module ChoiceEffects
  # The ability whose modifier adds to the armour class without armour (barbarian: Constitution, monk: Wisdom), read
  # by the rule unarmored_armor_class
  class UnarmoredDefense < Base
    KEY = "unarmored_defense".freeze
    TARGET_TYPE = "ability".freeze

    def target_keys(value)
      [value.to_s]
    end
  end
end
