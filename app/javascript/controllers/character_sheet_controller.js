import { Controller } from "@hotwired/stimulus"

// Keeps the computed values of a character sheet up to date while the player types: the modifier of each ability,
// the level reached, the proficiency bonus of that level, and the bonus of each saving throw and skill (modifier,
// plus the proficiency when ticked). Same rules as CharacterSheetCalculator (app/services), which works them out
// on the server: changing one means changing the other. Nothing here is sent: the server stores only what was typed
export default class extends Controller {
  static targets = ["score", "experience", "proficient", "modifier", "level", "computed", "bonus"]
  static values = { levelThresholds: Array }

  connect() {
    this.recompute()
  }

  recompute() {
    const threshold = this.reachedThreshold()
    const modifiers = this.abilityModifiers()
    const computedValues = this.computedValues(threshold)

    this.levelTargets.forEach((output) => { output.textContent = threshold?.level ?? "" })
    this.modifierTargets.forEach((output) => { output.textContent = formatBonus(modifiers[output.dataset.ability]) })
    this.computedTargets.forEach((output) => { output.textContent = formatBonus(computedValues[output.dataset.key]) })
    this.bonusTargets.forEach((output) => {
      output.textContent = formatBonus(this.bonusOf(output, modifiers, computedValues))
    })
  }

  // (score - 10) / 2, rounded down: 14 gives +2, 9 gives -1. No score yet: no modifier
  abilityModifiers() {
    return Object.fromEntries(this.scoreTargets.map((input) => {
      const score = parseInteger(input.value)
      return [input.dataset.ability, score === null ? null : Math.floor((score - 10) / 2)]
    }))
  }

  // proficiency_by_level is the only rule for now (SheetTemplate::COMPUTED_RULES)
  computedValues(threshold) {
    return Object.fromEntries(this.computedTargets.map((output) => {
      const value = output.dataset.rule === "proficiency_by_level" ? threshold?.proficiency_bonus : null
      return [output.dataset.key, value ?? null]
    }))
  }

  bonusOf(output, modifiers, computedValues) {
    const modifier = modifiers[output.dataset.basedOn]
    if (modifier === null || modifier === undefined) return null

    const isProficient = document.getElementById(output.dataset.proficientBox)?.checked
    return modifier + (isProficient ? (computedValues[output.dataset.proficiency] ?? 0) : 0)
  }

  // The last threshold the experience has reached; nothing typed counts as 0
  reachedThreshold() {
    const experience = parseInteger(this.experienceTargets[0]?.value) ?? 0
    const thresholds = [...this.levelThresholdsValue].sort((first, second) => first.experience - second.experience)
    return thresholds.reverse().find((threshold) => experience >= threshold.experience)
  }
}

function parseInteger(text) {
  const trimmedText = (text ?? "").trim()
  return /^-?\d+$/.test(trimmedText) ? Number.parseInt(trimmedText, 10) : null
}

// Same as format_bonus (CharacterSheetsHelper): +2, -1, or a dash while it cannot be worked out
function formatBonus(value) {
  if (value === null || value === undefined) return "—"

  return value < 0 ? `${value}` : `+${value}`
}
