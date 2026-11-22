import spellAttackBonus from "computed_rules/spell_attack_bonus"

// ComputedRules::SpellSaveDc: 8 + the spell attack bonus, a plain number kept as a text ("13", not "+13")
export default function spellSaveDc(settings, reader) {
  const attack = spellAttackBonus(settings, reader)
  return attack === null ? null : `${8 + attack}`
}
