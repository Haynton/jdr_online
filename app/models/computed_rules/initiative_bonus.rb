module ComputedRules
  # The initiative: the modifier of the ability based_on (Dexterity), plus the proficiency bonus (the computed field
  # proficiency) when a feat of the character gives it (the effect initiative_proficiency: Alert, decision of
  # 27 November). Reads as a bonus: +4. Not worked out by the page: its feats are known to the server only
  class InitiativeBonus < Base
    KEY = "initiative_bonus".freeze
    REQUIRED_PARAMETERS = %w[based_on proficiency].freeze
    LIVE = false

    def value(field, reader)
      modifier = reader.modifier(field["based_on"])
      return unless modifier

      bonus = reader.feat_effects["initiative_proficiency"] ? reader.proficiency(field["proficiency"]) : 0
      modifier + bonus
    end
  end
end
