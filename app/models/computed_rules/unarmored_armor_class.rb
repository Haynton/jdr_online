module ComputedRules
  # 10 + the modifier of based_on (Dexterity), + the modifier of the ability of the unarmored_defense of the class
  # chosen in class_from (Constitution for the barbarian, Wisdom for the monk). A plain number, kept as a text ("13").
  # Nothing until based_on has a score
  class UnarmoredArmorClass < Base
    KEY = "unarmored_armor_class".freeze
    REQUIRED_PARAMETERS = %w[based_on].freeze

    def value(field, reader)
      modifier = reader.modifier(field["based_on"])
      return unless modifier

      defense_ability = reader.class_effects(field["class_from"])["unarmored_defense"]
      (10 + modifier + reader.modifier(defense_ability).to_i).to_s
    end
  end
end
