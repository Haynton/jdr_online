module ComputedRules
  # 8 + the spell attack bonus (SpellAttackBonus): a plain number, kept as a text like the hit dice ("13", not "+13")
  class SpellSaveDc < SpellAttackBonus
    KEY = "spell_save_dc".freeze

    def value(field, reader)
      super&.then { |attack| (8 + attack).to_s }
    end
  end
end
