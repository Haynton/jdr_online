// The twins, for the page, of the modifier rules of app/models/modifier_rules (ModifierRules): changing one means
// changing the other
import halfAboveTen from "modifier_rules/half_above_ten"

const modifierRules = { half_above_ten: halfAboveTen }

// null without a score, or for a rule without a twin
export function modifierOf(score, ruleKey) {
  if (score === null) return null

  return modifierRules[ruleKey]?.(score) ?? null
}
