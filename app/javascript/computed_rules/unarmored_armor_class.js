// ComputedRules::UnarmoredArmorClass: 10 + the modifier of basedOn, + the modifier of the ability of the unarmored
// defense of the class chosen. A plain number, as a text
export default function unarmoredArmorClass({ basedOn, classFrom }, reader) {
  const modifier = reader.modifier(basedOn)
  if (modifier === null) return null

  const defenseAbility = reader.classEffects(classFrom).unarmored_defense
  return `${10 + modifier + (reader.modifier(defenseAbility) ?? 0)}`
}
