import { Controller } from "@hotwired/stimulus"

// Keeps the computed values of a character sheet up to date while the player types: the modifier of each ability,
// the proficiency bonus of the level typed, the initiative, and the bonus of each saving throw and skill (modifier,
// plus the proficiency when ticked). Same rules as CharacterSheetCalculator (app/services), which works them out
// on the server: changing one means changing the other. Nothing here is sent: the server stores only what was typed.
// It also applies the effects of an option picked in a list (the class ticks its saving throws, offers its skills).
// A step of the creation shows only some fields: the others are read from what the server gives (sheet: the values
// saved, effects: the effects of each list, calculated: its modifiers and computed values)
export default class extends Controller {
  static targets = ["score", "modifier", "computed", "bonus", "effectChoice", "bonusRow", "skillChoices"]
  static values = { levelThresholds: Array, sheet: Object, effects: Object, calculated: Object }

  connect() {
    this.appliedOptions = Object.fromEntries(this.effectChoiceTargets.map((select) => [select.id, select.value]))
    this.recompute()
  }

  recompute() {
    const modifiers = this.abilityModifiers()
    const computedValues = this.computedValues(modifiers)

    this.modifierTargets.forEach((output) => { output.textContent = formatBonus(modifiers[output.dataset.ability]) })
    this.computedTargets.forEach((output) => { output.textContent = formatComputed(computedValues[output.dataset.key]) })
    this.bonusTargets.forEach((output) => { output.textContent = formatBonus(this.bonusOf(output, modifiers)) })
    this.showSkillChoices()
  }

  // The effects of the option picked in a list (SheetTemplate::CHOICE_EFFECTS): its saving throws are ticked, those
  // of the option picked before are unticked (decision: replaced). Only an aid: the player can still change any box.
  // Runs before recompute, which the change then reaches on the form
  applyEffects({ target: select }) {
    const effectsByOption = JSON.parse(select.dataset.effects)
    const previousEffects = effectsByOption[this.appliedOptions[select.id]] ?? {}
    const pickedEffects = effectsByOption[select.value] ?? {}
    this.tickBonusFields(previousEffects.proficient, false)
    this.tickBonusFields(pickedEffects.proficient, true)
    this.writeFields(previousEffects.set, pickedEffects.set)
    this.appliedOptions[select.id] = select.value
  }

  // set: the values of the option picked are written (speed, size of a species); a field the option picked before
  // had filled, and the new one does not, is emptied
  writeFields(previousValues = {}, pickedValues = {}) {
    Object.keys(previousValues).filter((fieldKey) => !(fieldKey in pickedValues))
      .forEach((fieldKey) => this.writeField(fieldKey, ""))
    Object.entries(pickedValues).forEach(([fieldKey, value]) => this.writeField(fieldKey, value))
  }

  writeField(fieldKey, value) {
    const field = this.element.querySelector(`#character_sheet_${fieldKey}`)
    if (field) field.value = `${value}`
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
  // A list of another step (the class, on the skills step) gives the option saved
  pickedEffects() {
    return Object.keys(this.effectsValue).flatMap((fieldKey) => {
      const select = this.element.querySelector(`#character_sheet_${fieldKey}`)
      const option = select ? select.value : this.sheetValue[fieldKey]
      const effects = this.effectsValue[fieldKey][option]
      return effects ? [{ option, effects }] : []
    })
  }

  // The modifier of each score by the rule of its ability (SheetTemplate::MODIFIER_RULES). No score yet: no modifier
  abilityModifiers() {
    const modifiersOnPage = Object.fromEntries(this.scoreTargets.map((input) => {
      return [input.dataset.ability, modifierOf(parseInteger(input.value), input.dataset.modifierRule)]
    }))
    return { ...this.calculatedValue.modifiers, ...modifiersOnPage }
  }

  // The rules of SheetTemplate::COMPUTED_RULES, as in CharacterSheetCalculator#computed_value
  computedValues(modifiers) {
    return Object.fromEntries(this.computedTargets.map((output) => {
      const valuesByRule = {
        proficiency_by_level: () => this.thresholdOfLevel(output.dataset.levelFrom)?.proficiency_bonus,
        ability_modifier: () => modifiers[output.dataset.basedOn],
        hit_dice_by_class: () => this.hitDice(output),
        spell_save_dc: () => { const attack = this.spellAttack(output, modifiers); return attack === null ? null : `${8 + attack}` },
        spell_attack_bonus: () => this.spellAttack(output, modifiers),
        hit_points_by_level: () => asText(this.hitPoints(output, modifiers)),
        unarmored_armor_class: () => asText(this.unarmoredArmorClass(output, modifiers))
      }
      return [output.dataset.key, valuesByRule[output.dataset.rule]?.() ?? null]
    }))
  }

  // "3d8": one die per level, its sides the hit_die of the class chosen. Nothing until a class of the list is chosen
  hitDice(output) {
    const sides = this.classEffects(output.dataset.classFrom).hit_die
    return sides ? `${this.typedLevel(output.dataset.levelFrom)}d${sides}` : null
  }

  // The proficiency plus the modifier of the spellcasting ability of the class chosen; nothing for a class without
  // spells, or until that ability has a score. The save DC adds 8 and reads as a plain number (a text, like 3d8)
  spellAttack(output, modifiers) {
    const modifier = modifiers[this.classEffects(output.dataset.classFrom).spellcasting?.ability]
    if (modifier === null || modifier === undefined) return null

    return modifier + this.proficiencyOf(output.dataset.proficiency)
  }

  // Level 1: the highest roll of the die, then its average (half plus one) at each level, the modifier added each time
  hitPoints(output, modifiers) {
    const sides = this.classEffects(output.dataset.classFrom).hit_die
    const modifier = modifiers[output.dataset.basedOn]
    if (!sides || modifier === null || modifier === undefined) return null

    return sides + modifier + (this.typedLevel(output.dataset.levelFrom) - 1) * (Math.floor(sides / 2) + 1 + modifier)
  }

  // 10 + the modifier of basedOn, + the modifier of the ability of the unarmored defense of the class
  unarmoredArmorClass(output, modifiers) {
    const modifier = modifiers[output.dataset.basedOn]
    if (modifier === null || modifier === undefined) return null

    return 10 + modifier + (modifiers[this.classEffects(output.dataset.classFrom).unarmored_defense] ?? 0)
  }

  // The proficiency bonus of the level, from the computed field named (its rule: proficiency_by_level), or the value
  // the server worked out when that field is on another step
  proficiencyOf(fieldKey) {
    const output = this.computedTargets.find((computed) => computed.dataset.key === fieldKey)
    if (!output) return this.calculatedValue.values?.[fieldKey] ?? 0

    return this.thresholdOfLevel(output.dataset.levelFrom)?.proficiency_bonus ?? 0
  }

  // The effects of the option chosen in a list ({} before a choice): from the list on the page, or from the value
  // saved on another step
  classEffects(fieldKey) {
    const select = this.element.querySelector(`#character_sheet_${fieldKey}`)
    if (select) return JSON.parse(select.dataset.effects || "{}")[select.value] ?? {}

    return this.effectsValue[fieldKey]?.[this.sheetValue[fieldKey]] ?? {}
  }

  bonusOf(output, modifiers) {
    const modifier = modifiers[output.dataset.basedOn]
    if (modifier === null || modifier === undefined) return null

    const isProficient = document.getElementById(output.dataset.proficientBox)?.checked
    return modifier + (isProficient ? this.proficiencyOf(output.dataset.proficiency) : 0)
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

  // The value typed on the page, or the one saved on another step (the level, given by the table)
  fieldValue(fieldKey) {
    const field = this.element.querySelector(`#character_sheet_${fieldKey}`)
    if (field) return field.value

    const savedValue = this.sheetValue[fieldKey]
    return savedValue === undefined || savedValue === null ? undefined : `${savedValue}`
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

// A plain number (hit points, armour class) is kept as a text, so that it reads 8 and not +8, as on the server
function asText(number) {
  return number === null || number === undefined ? null : `${number}`
}
