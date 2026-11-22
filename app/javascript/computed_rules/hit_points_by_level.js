// ComputedRules::HitPointsByLevel: at level 1 the highest roll of the hit die of the class plus the modifier of
// basedOn, then at each level the average of the die (half plus one) plus that modifier. A plain number, as a text
export default function hitPointsByLevel({ basedOn, levelFrom, classFrom }, reader) {
  const sides = reader.classEffects(classFrom).hit_die
  const modifier = reader.modifier(basedOn)
  if (!sides || modifier === null) return null

  const levelsAfterTheFirst = reader.typedLevel(levelFrom) - 1
  return `${sides + modifier + levelsAfterTheFirst * (Math.floor(sides / 2) + 1 + modifier)}`
}
