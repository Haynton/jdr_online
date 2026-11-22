import { Controller } from "@hotwired/stimulus"

// The summary of the options picked beside their lists (characters/_section_described_choices): each option of each
// list is rendered by the server, the one picked shown. When the player changes a list, the summary of the option
// now picked shows, or "nothing picked yet" when the list is emptied
export default class extends Controller {
  static targets = ["option", "empty"]

  show() {
    this.optionTargets.forEach((option) => {
      option.hidden = this.pickedOption(option.dataset.field) !== option.dataset.option
    })
    this.emptyTargets.forEach((empty) => { empty.hidden = this.pickedOption(empty.dataset.field) !== "" })
  }

  pickedOption(fieldKey) {
    return this.element.querySelector(`#character_sheet_${fieldKey}`)?.value ?? ""
  }
}
