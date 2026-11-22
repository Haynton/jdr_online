// ComputedRules::AbilityModifier: the modifier of the ability basedOn (the initiative), as a bonus (+2)
export default function abilityModifier({ basedOn }, reader) {
  return reader.modifier(basedOn)
}
