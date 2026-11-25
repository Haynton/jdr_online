import { Controller } from "@hotwired/stimulus"

// The details of a spell or an item in a window (shared/_details_dialog), at the Spells step and on the summary sheet:
// a "Details" button writes the name and the line of the entry in the title bar and copies its details, folded beside
// it ([data-details-dialog-content]), into the window. The buttons are rendered hidden and shown here, the folds hidden
// instead: without JavaScript, the details open in place. A native <dialog>: Escape closes it, and the focus goes back
// to the button (returnFocus)
export default class extends Controller {
  static targets = ["opener", "fold", "dialog", "title", "summary", "body"]

  connect() {
    this.openerTargets.forEach((opener) => { opener.hidden = false })
    this.foldTargets.forEach((fold) => { fold.hidden = true })
  }

  open({ currentTarget: opener, params: { name, summary } }) {
    this.opener = opener
    const details = opener.parentElement.querySelector("[data-details-dialog-content]")
    this.titleTarget.textContent = name
    this.summaryTarget.textContent = summary
    this.summaryTarget.hidden = !summary
    this.bodyTarget.replaceChildren(details.cloneNode(true))
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
