module ComputedRules
  # The proficiency (the computed field proficiency) plus the modifier of the spellcasting ability of the class chosen
  # in class_from. Reads as a bonus: +5. Nothing for a class without spells, or until that ability has a score
  class SpellAttackBonus < Base
    KEY = "spell_attack_bonus".freeze
    REQUIRED_PARAMETERS = %w[class_from proficiency].freeze

    def value(field, reader)
      modifier = reader.modifier(reader.class_effects(field["class_from"]).dig("spellcasting", "ability"))
      modifier + reader.proficiency(field["proficiency"]) if modifier
    end
  end
end
