import { Controller } from "@hotwired/stimulus"

// A window around a Turbo Frame (sheet_templates/fields/_dialog): a native <dialog>, opened once a page has loaded
// into the frame. Escape (native), a close button or a click beside it close it; closed, the frame is emptied, so that
// the next link loads its page again (a frame does not reload an address it already shows). A form saved in it closes
// it: the server then refreshes the page behind
export default class extends Controller {
  static targets = ["frame"]

  // showModal focuses the first button, the close cross: the window takes the focus itself instead
  open() {
    if (this.element.open) return

    this.element.showModal()
    this.element.focus()
  }

  close() {
    if (this.element.open) this.element.close()
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  // A refused form stays in the window, with its errors
  closeOnSuccess(event) {
    if (event.detail.success) this.close()
  }

  empty() {
    this.frameTarget.removeAttribute("src")
    this.frameTarget.replaceChildren()
  }
}
