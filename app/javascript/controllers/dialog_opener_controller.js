import { Controller } from "@hotwired/stimulus"

// Opens a native window from a button (« Donner de l'argent » in the panel « Objets »): the window takes the focus
// itself, Escape (native), a close button or a click beside it close it, and the focus goes back to the button. The
// buttons are rendered hidden and shown here: without JavaScript, no window opens
export default class extends Controller {
  static targets = ["opener", "dialog"]

  connect() {
    this.openerTargets.forEach((opener) => { opener.hidden = false })
  }

  open(event) {
    this.opener = event.currentTarget
    this.dialogTarget.showModal()
    this.dialogTarget.focus()
  }

  close() {
    this.dialogTarget.close()
    this.opener?.focus({ focusVisible: false })
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
