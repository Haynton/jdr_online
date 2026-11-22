// ComputedRules::SpellAttackBonus: the proficiency plus the modifier of the spellcasting ability of the class chosen,
// as a bonus (+5). Nothing for a class without spells, or until that ability has a score
export default function spellAttackBonus({ classFrom, proficiency }, reader) {
  const modifier = reader.modifier(reader.classEffects(classFrom).spellcasting?.ability)
  return modifier === null ? null : modifier + reader.proficiency(proficiency)
}
