import { Controller } from "@hotwired/stimulus"

// On a step of the creation of a character, following a step of the band (outside the form, a link carrying
// data-save-step-key) sends the form first, with that step in its destination field: the server saves the step, then
// opens the one followed (GameTables::CharacterStepsController, go_to). A link opened in a new tab keeps its usual
// behaviour. Without JavaScript, the link opens the step without saving
export default class extends Controller {
  static targets = ["destination"]

  connect() {
    this.followStep = this.followStep.bind(this)
    document.addEventListener("click", this.followStep)
  }

  disconnect() {
    document.removeEventListener("click", this.followStep)
  }

  followStep(event) {
    const link = event.target.closest("a[data-save-step-key]")
    if (!link || event.defaultPrevented || isOpeningElsewhere(event)) return

    event.preventDefault()
    this.destinationTarget.value = link.dataset.saveStepKey
    this.element.requestSubmit()
  }
}

function isOpeningElsewhere(event) {
  return event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey
}
