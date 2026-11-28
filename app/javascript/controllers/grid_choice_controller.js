import { Controller } from "@hotwired/stimulus"

// A list picked on a grid of two axes (character_sheets/fields/_grid_choice: the alignment, its order and its morals):
// once a value is chosen on each axis, the option of their cell is written in the real list, which the form sends
// (and the autosave hears: a change event), and its meaning is shown. The axes are shown instead of the list by CSS
export default class extends Controller {
  static targets = ["fallback", "radio", "meaning"]
  static values = { options: Array }

  pick() {
    const column = this.chosenIndex("columns")
    const row = this.chosenIndex("rows")
    if (column === null || row === null) return

    const option = this.optionsValue[row][column]
    this.list.value = option
    this.list.dispatchEvent(new Event("change", { bubbles: true }))
    this.showMeaning(option)
  }

  chosenIndex(axis) {
    const radio = this.radioTargets.find((target) => target.dataset.axis === axis && target.checked)
    return radio ? Number(radio.value) : null
  }

  showMeaning(option) {
    this.meaningTargets.forEach((meaning) => meaning.toggleAttribute("data-shown", meaning.dataset.option === option))
  }

  get list() {
    return this.fallbackTarget.querySelector("select")
  }
}
