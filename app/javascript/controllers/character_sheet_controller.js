import { Controller } from "@hotwired/stimulus"

// Keeps the computed values of a character sheet up to date while the player types: the modifier of each ability,
// the proficiency bonus of the level typed, the initiative, and the bonus of each saving throw and skill (modifier,
// plus the proficiency when ticked). Same rules as CharacterSheetCalculator (app/services), which works them out
// on the server: changing one means changing the other. Nothing here is sent: the server stores only what was typed.
// It also applies the effects of an option picked in a list (the class ticks its saving throws, offers its skills)
export default class extends Controller {
  static targets = ["score", "modifier", "computed", "bonus", "effectChoice", "bonusRow", "skillChoices"]
  static values = { levelThresholds: Array }

  connect() {
    this.appliedOptions = Object.fromEntries(this.effectChoiceTargets.map((select) => [select.id, select.value]))
    this.recompute()
  }

  recompute() {
    const modifiers = this.abilityModifiers()
    const computedValues = this.computedValues(modifiers)

    this.modifierTargets.forEach((output) => { output.textContent = formatBonus(modifiers[output.dataset.ability]) })
    this.computedTargets.forEach((output) => { output.textContent = formatComputed(computedValues[output.dataset.key]) })
    this.bonusTargets.forEach((output) => {
      output.textContent = formatBonus(this.bonusOf(output, modifiers, computedValues))
    })
    this.showSkillChoices()
  }

  // The effects of the option picked in a list (SheetTemplate::CHOICE_EFFECTS): its saving throws are ticked, those
  // of the option picked before are unticked (decision: replaced). Only an aid: the player can still change any box.
  // Runs before recompute, which the change then reaches on the form
  applyEffects({ target: select }) {
    const effectsByOption = JSON.parse(select.dataset.effects)
    this.tickBonusFields(effectsByOption[this.appliedOptions[select.id]]?.proficient, false)
    this.tickBonusFields(effectsByOption[select.value]?.proficient, true)
    this.appliedOptions[select.id] = select.value
  }

  tickBonusFields(fieldKeys = [], isTicked) {
    fieldKeys.forEach((fieldKey) => {
      const checkBox = this.element.querySelector(`#character_sheet_${fieldKey}`)
      if (checkBox) checkBox.checked = isTicked
    })
  }

  // The skills offered by the options picked (skill_choices) are marked, and the count of those ticked is written
  // under the title of their section. Nothing to show while no option offers any
  showSkillChoices() {
    const offers = this.pickedEffects().filter(({ effects }) => effects.skill_choices)
    const offeredKeys = new Set(offers.flatMap(({ effects }) => effects.skill_choices.from))
    this.bonusRowTargets.forEach((row) => row.toggleAttribute("data-offered", offeredKeys.has(row.dataset.key)))
    this.skillChoicesTargets.forEach((paragraph) => this.writeSkillChoices(paragraph, offers, offeredKeys))
  }

  writeSkillChoices(paragraph, offers, offeredKeys) {
    paragraph.hidden = offers.length === 0
    if (paragraph.hidden) return

    const tickedCount = [...offeredKeys].filter((fieldKey) => {
      return this.element.querySelector(`#character_sheet_${fieldKey}`)?.checked
    }).length
    paragraph.textContent = paragraph.dataset.template
      .replace("%{option}", offers.map(({ option }) => option).join(", "))
      .replaceAll("%{count}", offers.reduce((total, { effects }) => total + effects.skill_choices.count, 0))
      .replace("%{chosen}", tickedCount)
  }

  // [{ option: "Magicien", effects: { ... } }] for each list with effects, once an option is picked
  pickedEffects() {
    return this.effectChoiceTargets.flatMap((select) => {
      const effects = JSON.parse(select.dataset.effects)[select.value]
      return effects ? [{ option: select.value, effects }] : []
    })
  }

  // The modifier of each score by the rule of its ability (SheetTemplate::MODIFIER_RULES). No score yet: no modifier
  abilityModifiers() {
    return Object.fromEntries(this.scoreTargets.map((input) => {
      return [input.dataset.ability, modifierOf(parseInteger(input.value), input.dataset.modifierRule)]
    }))
  }

  // The rules of SheetTemplate::COMPUTED_RULES, as in CharacterSheetCalculator#computed_value
  computedValues(modifiers) {
    return Object.fromEntries(this.computedTargets.map((output) => {
      const valuesByRule = {
        proficiency_by_level: () => this.thresholdOfLevel(output.dataset.levelFrom)?.proficiency_bonus,
        ability_modifier: () => modifiers[output.dataset.basedOn],
        hit_dice_by_class: () => this.hitDice(output)
      }
      return [output.dataset.key, valuesByRule[output.dataset.rule]?.() ?? null]
    }))
  }

  // "3d8": one die per level, its sides the hit_die of the class chosen (effects of its list). Nothing until a class
  // of the list is chosen
  hitDice(output) {
    const classSelect = this.element.querySelector(`#character_sheet_${output.dataset.classFrom}`)
    const effectsByOption = JSON.parse(classSelect?.dataset.effects || "{}")
    const sides = effectsByOption[classSelect?.value]?.hit_die
    return sides ? `${this.typedLevel(output.dataset.levelFrom)}d${sides}` : null
  }

  bonusOf(output, modifiers, computedValues) {
    const modifier = modifiers[output.dataset.basedOn]
    if (modifier === null || modifier === undefined) return null

    const isProficient = document.getElementById(output.dataset.proficientBox)?.checked
    return modifier + (isProficient ? (computedValues[output.dataset.proficiency] ?? 0) : 0)
  }

  // The threshold of the level typed in the field levelFrom: the last one at or under it
  thresholdOfLevel(levelFrom) {
    const level = this.typedLevel(levelFrom)
    const thresholds = [...this.levelThresholdsValue].sort((first, second) => first.level - second.level)
    return thresholds.reverse().find((threshold) => level >= threshold.level)
  }

  // Nothing typed is level 1
  typedLevel(levelFrom) {
    return parseInteger(this.fieldValue(levelFrom)) ?? 1
  }

  fieldValue(fieldKey) {
    return this.element.querySelector(`#character_sheet_${fieldKey}`)?.value
  }
}

// Same as CharacterSheetCalculator.modifier. half_above_ten: (score - 10) / 2, rounded down: 14 gives +2, 9 gives -1
function modifierOf(score, rule) {
  if (score === null) return null

  return rule === "half_above_ten" ? Math.floor((score - 10) / 2) : null
}

function parseInteger(text) {
  const trimmedText = (text ?? "").trim()
  return /^-?\d+$/.test(trimmedText) ? Number.parseInt(trimmedText, 10) : null
}

// Same as format_bonus (CharacterSheetValuesHelper): +2, -1, or a dash while it cannot be worked out
function formatBonus(value) {
  if (value === null || value === undefined) return "—"

  return value < 0 ? `${value}` : `+${value}`
}

// Same as format_computed_value: a text as it is (hit dice: 3d8), a number as a bonus
function formatComputed(value) {
  return typeof value === "string" ? value : formatBonus(value)
}
