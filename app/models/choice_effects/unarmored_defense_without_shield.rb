module ChoiceEffects
  # The unarmored defense of the class counts only without a shield equipped (the monk, in the 2024 rules; the
  # barbarian keeps it with a shield), read by the rule worn_armor_class. Its value is true
  class UnarmoredDefenseWithoutShield < Base
    KEY = "unarmored_defense_without_shield".freeze

    def value_errors(value, **)
      value == true ? [] : [[:unknown_effect_value, { effect: KEY, value: value.to_s }]]
    end
  end
end
