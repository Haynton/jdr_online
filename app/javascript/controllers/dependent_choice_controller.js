import { Controller } from "@hotwired/stimulus"

// A list that depends on another list and on a level (the subclass: those of the class picked, from level 3), as
// FieldTypes::Choice on the server: while the player changes the class or the level on the same page, the list offers
// the options of the class picked, and shows only from its level, with what goes with it (data-shown-with: its
// summary beside the lists). A value no longer offered is emptied, and a change is sent, so that the effects of the
// option gone are taken back (character_sheet_controller.js#applyEffects). The list or the level on another step are
// read from what was saved. The server takes the value out too (CharacterSheets::UnofferedValuesRemover)
export default class extends Controller {
  static values = {
    fieldKey: String, optionsFrom: String, optionsBy: Object, savedOption: String,
    fromLevel: Number, levelFrom: String, savedLevel: Number
  }

  connect() {
    const select = this.element.querySelector("select")
    this.allOptions = select ? [...select.options].map(({ value }) => value).filter(Boolean) : []
    this.refresh()
  }

  refresh() {
    const select = this.element.querySelector("select")
    if (!select) return

    const offeredOptions = this.offeredOptions()
    const asked = this.levelReached() && offeredOptions.length > 0
    this.offer(select, asked ? offeredOptions : [])
    this.element.hidden = !asked
    document.querySelectorAll(`[data-shown-with="${this.fieldKeyValue}"]`)
      .forEach((element) => { element.hidden = !asked })
  }

  // The options of the option picked in the list it depends on, or all of them for a list that depends on none
  offeredOptions() {
    if (!this.optionsFromValue) return this.allOptions

    return this.optionsByValue[this.fieldValue(this.optionsFromValue) ?? this.savedOptionValue] ?? []
  }

  // No level typed counts as level 1, as the rules read it
  levelReached() {
    if (!this.hasFromLevelValue) return true

    const savedLevel = this.hasSavedLevelValue ? `${this.savedLevelValue}` : undefined
    const typedLevel = Number.parseInt(this.fieldValue(this.levelFromValue) ?? savedLevel, 10)
    return (Number.isNaN(typedLevel) ? 1 : typedLevel) >= this.fromLevelValue
  }

  // The list rebuilt only when what it offers changes (not at each key typed elsewhere), the blank option first
  offer(select, options) {
    const shownOptions = [...select.options].map(({ value }) => value).filter(Boolean)
    if (shownOptions.join("\n") === options.join("\n")) return

    const pickedOption = select.value
    select.replaceChildren(new Option("", ""), ...options.map((option) => new Option(option, option)))
    select.value = options.includes(pickedOption) ? pickedOption : ""
    if (select.value !== pickedOption) select.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // The value of a field on the page, undefined when it is on another step
  fieldValue(fieldKey) {
    return this.element.ownerDocument.getElementById(`character_sheet_${fieldKey}`)?.value
  }
}
