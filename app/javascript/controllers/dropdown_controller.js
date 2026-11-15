import { Controller } from "@hotwired/stimulus"

// A button that shows or hides a list of links under it (disclosure pattern: no role="menu",
// so Tab moves through the links like everywhere else on the page).
// Closes with Escape, a click elsewhere, or when the keyboard focus leaves it.
export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // Escape: the focus goes back to the button, so a keyboard user does not get lost
  closeAndFocusButton() {
    if (!this.isOpen()) return

    this.close()
    this.buttonTarget.focus()
  }

  closeOnOutsideClick(event) {
    if (this.element.contains(event.target)) return

    this.close()
  }

  // Only a focus going somewhere else on the page closes it. Safari does not focus a link on click:
  // relatedTarget is then empty, and closing here would hide the menu before the click reaches the link
  closeOnFocusLeave(event) {
    if (!event.relatedTarget || this.element.contains(event.relatedTarget)) return

    this.close()
  }

  isOpen() {
    return !this.menuTarget.hidden
  }
}
