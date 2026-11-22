// ComputedRules::HitDiceByClass: "3d8", one die per level, its sides the hit die of the class chosen
export default function hitDiceByClass({ levelFrom, classFrom }, reader) {
  const sides = reader.classEffects(classFrom).hit_die
  return sides ? `${reader.typedLevel(levelFrom)}d${sides}` : null
}
