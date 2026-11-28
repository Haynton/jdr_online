import { Controller } from "@hotwired/stimulus"

// A list opened with the pointer lets go of the focus once a pick is made (decision: its focus mark stayed on screen
// after a click, Chrome treating a list as reached with the keyboard). Reached with the keyboard, it keeps its focus
// and its mark (WCAG 2.4.7)
export default class extends Controller {
  remember() {
    this.pickedWithPointer = true
  }

  // Closed without a pick: a pick made later with the keyboard keeps the focus
  forget() {
    this.pickedWithPointer = false
  }

  release() {
    if (!this.pickedWithPointer) return

    this.pickedWithPointer = false
    this.element.blur()
  }
}
