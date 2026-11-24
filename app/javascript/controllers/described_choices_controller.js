import { Controller } from "@hotwired/stimulus"

// The summary of the options picked beside their lists (character_sheets/sections/_described_choices): each option of each
// list is rendered by the server, the one picked shown. When the player changes a list, the summary of the option
// now picked shows, or "nothing picked yet" when the list is emptied. A fact given from a level (data-from-level: the
// features of a subclass) shows once the level typed reaches it
export default class extends Controller {
  static targets = ["option", "empty"]

  show() {
    this.optionTargets.forEach((option) => {
      option.hidden = this.pickedOption(option.dataset.field) !== option.dataset.option
    })
    this.emptyTargets.forEach((empty) => { empty.hidden = this.pickedOption(empty.dataset.field) !== "" })
    this.element.querySelectorAll("[data-from-level]").forEach((fact) => {
      fact.hidden = this.levelOf(fact) < Number(fact.dataset.fromLevel)
    })
  }

  // The level typed on the page, or the one saved; none counts as level 1
  levelOf(fact) {
    const typedLevel = document.getElementById(`character_sheet_${fact.dataset.levelFrom}`)?.value
    const level = Number.parseInt(typedLevel ?? fact.dataset.savedLevel, 10)
    return Number.isNaN(level) ? 1 : level
  }

  pickedOption(fieldKey) {
    return this.element.querySelector(`#character_sheet_${fieldKey}`)?.value ?? ""
  }
}
