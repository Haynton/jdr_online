import { Controller } from "@hotwired/stimulus"

// A list of lines the user adds and removes (the attacks of a monster): "Add" copies the template of a line, with a
// position of its own in the names of its fields (the placeholder NEW_LINE replaced), and puts the focus in its first
// field; "Remove" takes its line out. The buttons are rendered hidden and shown here: without JavaScript, the page has
// a blank line of its own instead, removed here
export default class extends Controller {
  static targets = ["list", "template", "line", "blankLine", "addButton", "removeButton"]

  connect() {
    this.blankLineTargets.forEach((blankLine) => blankLine.remove())
    this.addButtonTarget.hidden = false
    this.removeButtonTargets.forEach((button) => { button.hidden = false })
  }

  removeButtonTargetConnected(button) {
    button.hidden = false
  }

  add() {
    const position = `${Date.now()}`
    const markup = this.templateTarget.innerHTML.replaceAll("NEW_LINE", position)
    this.listTarget.insertAdjacentHTML("beforeend", markup)
    this.lineTargets.at(-1).querySelector("input")?.focus()
  }

  remove({ currentTarget: button }) {
    button.closest("[data-repeated-lines-target='line']").remove()
    this.addButtonTarget.focus()
  }
}
