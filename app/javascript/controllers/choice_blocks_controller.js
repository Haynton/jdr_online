import { Controller } from "@hotwired/stimulus"

// Blocks that go with a choice (decision of 27 November: no second sending of a form): the server prepares the block
// of each value of a list or of radio buttons (data-choice-value), hidden; the block of the value picked shows at once,
// and the fields of the others are turned off, so that only its fields are sent. Used by the window of a level gained:
// what a subclass brings, what a feat asks. Without JavaScript, the block of the value picked shows when the form
// comes back
export default class extends Controller {
  static targets = ["choice", "block"]

  connect() {
    this.show()
  }

  show() {
    const picked = this.pickedValue()
    this.blockTargets.forEach((block) => {
      const shown = block.dataset.choiceValue === picked
      block.hidden = !shown
      block.querySelectorAll("input, select, textarea").forEach((field) => { field.disabled = !shown })
    })
  }

  // The value of the list, or of the radio button ticked
  pickedValue() {
    const checked = this.choiceTargets.find((choice) => choice.type !== "radio" || choice.checked)
    return checked ? checked.value : ""
  }
}
