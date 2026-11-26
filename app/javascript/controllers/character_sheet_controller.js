import { Controller } from "@hotwired/stimulus"
import { applyChoiceEffects } from "choice_effects"
import { computedValue } from "computed_rules"
import { modifierOf } from "modifier_rules"

// Keeps the computed values of a character sheet up to date while the player types: the modifier of each ability,
// the proficiency bonus of the level typed, the initiative, and the bonus of each saving throw and skill (modifier,
// plus the proficiency when ticked). Same rules as CharacterSheets::Calculator (app/services), which works them out
// on the server: changing one means changing the other. Nothing here is sent: the server stores only what was typed.
// It also applies the effects of an option picked in a list (the class ticks its saving throws, offers its skills).
// A step of the creation shows only some fields: the others are read from what the server gives (sheet: the values
// saved, effects: the effects of each list, calculated: its modifiers and computed values)
export default class extends Controller {
  static targets = ["score", "modifier", "computed", "bonus", "effectChoice", "bonusRow", "skillChoices", "abilityBonus",
    "finalScore", "bonusNote"]
  static values = { levelThresholds: Array, sheet: Object, effects: Object, calculated: Object, refinements: Object }

  connect() {
    this.appliedOptions = Object.fromEntries(this.effectChoiceTargets.map((select) => [select.id, select.value]))
    this.recompute()
  }

  recompute() {
    this.scoreTargets.forEach((input) => this.showBonusInScore(input))
    const modifiers = this.abilityModifiers()
    const computedValues = this.computedValues(modifiers)

    this.modifierTargets.forEach((output) => { output.textContent = formatBonus(modifiers[output.dataset.ability]) })
    this.finalScoreTargets.forEach((output) => { output.textContent = this.finalScore(output.dataset.ability) ?? "—" })
    this.bonusNoteTargets.forEach((note) => this.writeBonusNote(note))
    this.computedTargets.forEach((output) => { output.textContent = formatComputed(computedValues[output.dataset.key]) })
    this.bonusTargets.forEach((output) => { output.textContent = formatBonus(this.bonusOf(output, modifiers)) })
    this.showSkillChoices()
  }

  // The effects of the option picked in a list, each by its twin (app/javascript/choice_effects): its saving throws
  // are ticked, those of the option picked before are unticked (decision: replaced), its speed is written. Only an
  // aid: the player can still change any box. Runs before recompute, which the change then reaches on the form
  applyEffects({ target: select }) {
    const effectsByOption = JSON.parse(select.dataset.effects)
    const previousEffects = effectsByOption[this.appliedOptions[select.id]] ?? {}
    const pickedEffects = effectsByOption[select.value] ?? {}
    applyChoiceEffects(previousEffects, pickedEffects, this.page())
    this.appliedOptions[select.id] = select.value
  }

  // What the effects may change on the page: a box ticked or not, a field written (a field of another step is left)
  page() {
    const fieldOf = (fieldKey) => this.element.querySelector(`#character_sheet_${fieldKey}`)
    return {
      tickBox: (fieldKey, isTicked) => { const checkBox = fieldOf(fieldKey); if (checkBox) checkBox.checked = isTicked },
      writeField: (fieldKey, value) => { const field = fieldOf(fieldKey); if (field) field.value = `${value}` }
    }
  }

  // The skills offered by the options picked (skill_choices) are marked, and the count of those ticked is written
  // under the title of their section. Nothing to show while no option offers any. A skill another option already
  // gives (proficient: the background ticks its own) is neither offered nor counted: the player picks the others
  showSkillChoices() {
    const pickedEffects = this.pickedEffects()
    const offers = pickedEffects.filter(({ effects }) => effects.skill_choices)
    const grantedKeys = new Set(pickedEffects.flatMap(({ effects }) => effects.proficient ?? []))
    const offeredKeys = new Set(offers.flatMap(({ effects }) => effects.skill_choices.from)
      .filter((fieldKey) => !grantedKeys.has(fieldKey)))
    this.bonusRowTargets.forEach((row) => row.toggleAttribute("data-offered", offeredKeys.has(row.dataset.key)))
    this.skillChoicesTargets.forEach((paragraph) => this.writeSkillChoices(paragraph, offers, offeredKeys))
  }

  writeSkillChoices(paragraph, offers, offeredKeys) {
    paragraph.hidden = offers.length === 0
    if (paragraph.hidden) return

    const tickedCount = [...offeredKeys].filter((fieldKey) => this.isTicked(fieldKey)).length
    const allowedCount = offers.reduce((total, { effects }) => total + effects.skill_choices.count, 0)
    paragraph.textContent = paragraph.dataset.template
      .replace("%{option}", offers.map(({ option }) => option).join(", "))
      .replaceAll("%{count}", allowedCount)
      .replace("%{chosen}", tickedCount)
    const isPastLimit = tickedCount > allowedCount || this.notOfferedTicked(offeredKeys)
    paragraph.toggleAttribute("data-invalid", paragraph.hasAttribute("data-limited") && isPastLimit)
  }

  // A skill some option of the template may offer, ticked, that the options picked neither offer nor give: refused
  // by the server when the table limits the skills (CharacterSheets::SkillChoices#not_offered_keys)
  notOfferedTicked(offeredKeys) {
    const grantedKeys = new Set(this.pickedEffects().flatMap(({ effects }) => effects.proficient ?? []))
    const skillKeys = Object.values(this.effectsValue).flatMap((effectsByOption) => {
      return Object.values(effectsByOption).flatMap((effects) => effects.skill_choices?.from ?? [])
    })
    return skillKeys.some((fieldKey) => {
      return !offeredKeys.has(fieldKey) && !grantedKeys.has(fieldKey) && this.isTicked(fieldKey)
    })
  }

  isTicked(fieldKey) {
    return this.element.querySelector(`#character_sheet_${fieldKey}`)?.checked ?? false
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

  // The modifier of each score by the rule of its ability (modifier_rules). No score yet: no modifier
  abilityModifiers() {
    const modifiersOnPage = Object.fromEntries(this.scoreTargets.map((input) => {
      return [input.dataset.ability, modifierOf(this.finalScore(input.dataset.ability), input.dataset.modifierRule)]
    }))
    return { ...this.calculatedValue.modifiers, ...modifiersOnPage }
  }

  // The score of a tile includes the bonus of the background placed on it (decision): 13 typed with +2 shows 15,
  // and the field cannot go under its part of bonus (its min is raised). The server keeps the score typed: the bonus
  // is taken off when the form is sent (sendTypedScores). data-shown-bonus says what the field holds; as an
  // attribute, it stays with a copy of the page by Turbo, which would otherwise add the bonus twice
  showBonusInScore(input) {
    const bonus = this.pickedBonus(input.dataset.ability)
    const shownBonus = Number(input.dataset.shownBonus ?? 0)
    const score = parseInteger(input.value)
    input.dataset.typedMin ??= input.min
    if (score !== null && bonus !== shownBonus) input.value = score + bonus - shownBonus
    if (input.dataset.typedMin !== "") input.min = Number(input.dataset.typedMin) + bonus
    // A point buy bounds the score typed too (15 at most): with the bonus shown, the score shown goes up as far
    if (input.dataset.typedMax) input.max = Number(input.dataset.typedMax) + bonus
    input.dataset.shownBonus = bonus
  }

  // "incl. +2 Soldier" under the score of a tile, empty while its bonus is +0 (its line stays: same size for all)
  writeBonusNote(note) {
    const bonus = this.pickedBonus(note.dataset.ability)
    note.textContent = bonus === 0 ? "" : note.dataset.template.replace("%{bonus}", bonus)
  }

  // The scores are sent as typed, without the bonus shown in them (formdata: the fields themselves stay as they are)
  sendTypedScores({ formData }) {
    this.scoreTargets.forEach((input) => {
      const score = parseInteger(input.value)
      if (score !== null) formData.set(input.name, score - Number(input.dataset.shownBonus ?? 0))
    })
  }

  pickedBonus(abilityKey) {
    const pickedChoice = this.abilityBonusTargets.find((choice) => choice.dataset.ability === abilityKey && choice.checked)
    return Number(pickedChoice?.value ?? 0)
  }

  // The score typed plus the bonus of the background picked for it (+0, +1 or +2), as
  // CharacterSheets::Calculator#ability_scores: what the tile shows (showBonusInScore). Nothing typed: no score
  finalScore(abilityKey) {
    const input = this.scoreTargets.find((score) => score.dataset.ability === abilityKey)
    return parseInteger(input?.value)
  }

  // Each computed field by its rule (app/javascript/computed_rules), as in CharacterSheets::Calculator
  computedValues(modifiers) {
    const reader = this.sheetReader(modifiers)
    return Object.fromEntries(this.computedTargets.map((output) => {
      return [output.dataset.key, computedValue(output.dataset.rule, output.dataset, reader)]
    }))
  }

  // What the rules read on the sheet, as CharacterSheets::SheetReader on the server
  sheetReader(modifiers) {
    return {
      modifier: (abilityKey) => modifiers[abilityKey] ?? null,
      typedLevel: (levelKey) => this.typedLevel(levelKey),
      thresholdOfLevel: (levelKey) => this.thresholdOfLevel(levelKey),
      classEffects: (listKey) => this.classEffects(listKey),
      proficiency: (proficiencyKey) => this.proficiencyOf(proficiencyKey)
    }
  }

  // The proficiency bonus of the level, from the computed field named (by its rule), or the value the server worked
  // out when that field is on another step
  proficiencyOf(fieldKey) {
    const output = this.computedTargets.find((computed) => computed.dataset.key === fieldKey)
    if (!output) return this.calculatedValue.values?.[fieldKey] ?? 0

    return computedValue(output.dataset.rule, output.dataset, this.sheetReader({})) ?? 0
  }

  // The effects of the option chosen in a list, with those of the lists that depend on it (refinements: the subclass
  // adds to its class), as CharacterSheets::SheetReader#class_effects
  classEffects(fieldKey) {
    return [fieldKey, ...(this.refinementsValue[fieldKey] ?? [])]
      .reduce((effects, listKey) => ({ ...effects, ...this.pickedEffectsOf(listKey) }), {})
  }

  // The effects of the option chosen in a list ({} before a choice): from the list on the page, or from the value
  // saved on another step
  pickedEffectsOf(fieldKey) {
    const select = this.element.querySelector(`#character_sheet_${fieldKey}`)
    if (select) return JSON.parse(select.dataset.effects || "{}")[select.value] ?? {}

    return this.effectsValue[fieldKey]?.[this.sheetValue[fieldKey]] ?? {}
  }

  bonusOf(output, modifiers) {
    const modifier = modifiers[output.dataset.basedOn]
    if (modifier === null || modifier === undefined) return null

    // The expertise (FieldTypes::Bonus: "expertise") counts the proficiency twice, and implies it
    const hasExpertise = document.getElementById(output.dataset.expertiseBox)?.checked
    const isProficient = hasExpertise || document.getElementById(output.dataset.proficientBox)?.checked
    const factor = hasExpertise ? 2 : (isProficient ? 1 : 0)
    return modifier + factor * this.proficiencyOf(output.dataset.proficiency)
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

function parseInteger(text) {
  const trimmedText = (text ?? "").trim()
  return /^-?\d+$/.test(trimmedText) ? Number.parseInt(trimmedText, 10) : null
}

// Same as format_bonus (CharacterSheets::ValuesHelper): +2, -1, or a dash while it cannot be worked out
function formatBonus(value) {
  if (value === null || value === undefined) return "—"

  return value < 0 ? `${value}` : `+${value}`
}

// Same as format_computed_value: a text as it is (hit dice: 3d8), a number as a bonus
function formatComputed(value) {
  return typeof value === "string" ? value : formatBonus(value)
}
