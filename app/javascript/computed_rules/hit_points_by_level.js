// ComputedRules::HitPointsByLevel: at level 1 the highest roll of the hit die of the class plus the modifier of
// basedOn, then at each level the average of the die (half plus one) plus that modifier, or, when the hit dice were
// rolled (reader.hitPointRolls, null otherwise), each roll plus that modifier, at least 1 a level. A plain number, as a
// text. Plus, at each level, the points an option adds (hit_points_per_level: the draconic resilience)
export default function hitPointsByLevel({ basedOn, levelFrom, classFrom }, reader) {
  const effects = reader.classEffects(classFrom)
  const sides = effects.hit_die
  const modifier = reader.modifier(basedOn)
  if (!sides || modifier === null) return null

  const pointsPerLevel = (effects.hit_points_per_level ?? 0) * reader.typedLevel(levelFrom)
  return `${sides + modifier + laterLevelsPoints(levelFrom, reader, sides, modifier) + pointsPerLevel}`
}

function laterLevelsPoints(levelFrom, reader, sides, modifier) {
  const rolls = reader.hitPointRolls?.() ?? null
  if (rolls) return rolls.reduce((total, roll) => total + Math.max(roll + modifier, 1), 0)

  return (reader.typedLevel(levelFrom) - 1) * (Math.floor(sides / 2) + 1 + modifier)
}
