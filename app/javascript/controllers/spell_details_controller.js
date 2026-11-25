import { Controller } from "@hotwired/stimulus"

// The details of a spell in a window, at the Spells step (game_tables/character_steps/_spell_details_dialog): "Details"
// on a card writes the name and the line of the spell in the title bar and copies its details, folded in the card,
// into the window. The buttons are rendered hidden and shown here, the folds hidden instead: without JavaScript, the
// details open under the card. A native <dialog>: Escape closes it, and the focus goes back to the button (returnFocus)
export default class extends Controller {
  static targets = ["opener", "fold", "dialog", "title", "summary", "body"]

  connect() {
    this.openerTargets.forEach((opener) => { opener.hidden = false })
    this.foldTargets.forEach((fold) => { fold.hidden = true })
  }

  open({ currentTarget: opener, params: { name, summary } }) {
    this.opener = opener
    const details = opener.closest("li").querySelector("[data-spell-details-content]")
    this.titleTarget.textContent = name
    this.summaryTarget.textContent = summary
    this.bodyTarget.replaceChildren(details.cloneNode(true))
    this.bodyTarget.firstElementChild.classList.remove("mt-2")
    this.bodyTarget.scrollTop = 0
    this.dialogTarget.showModal()
    // showModal focuses the first button, the close cross: the window takes the focus itself instead
    this.dialogTarget.focus()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // The focus goes back to "Details", even where the browser gave it none on the click (Safari)
  returnFocus() {
    this.opener?.focus()
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
