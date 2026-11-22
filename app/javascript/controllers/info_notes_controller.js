import { Controller } from "@hotwired/stimulus"

// The helps of the boxes of a row (hit points, initiative...), shown under the row only when asked: each box has a
// button (i) that opens or closes its note (aria-expanded, aria-controls). The notes are hidden and the buttons shown
// here: without JavaScript, every note stays shown and there is no button. A note stays tied to its field
// (aria-describedby), hidden or not
export default class extends Controller {
  static targets = ["note", "button"]

  connect() {
    this.noteTargets.forEach((note) => { note.hidden = true })
    this.buttonTargets.forEach((button) => { button.hidden = false })
  }

  toggle({ currentTarget: button }) {
    const note = this.noteTargets.find((candidate) => candidate.id === button.getAttribute("aria-controls"))
    if (!note) return

    note.hidden = !note.hidden
    this.buttonTargets.filter((candidate) => candidate.getAttribute("aria-controls") === note.id)
      .forEach((candidate) => candidate.setAttribute("aria-expanded", `${!note.hidden}`))
  }
}
