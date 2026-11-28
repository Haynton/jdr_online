import { Controller } from "@hotwired/stimulus"

// A row that scrolls sideways opens on its current element ([aria-current], the step of the creation in sight on a
// phone): it is brought to the middle of the row, the page itself does not move. Nothing to do when the row holds
export default class extends Controller {
  connect() {
    const current = this.element.querySelector("[aria-current]")
    if (!current || this.element.scrollWidth <= this.element.clientWidth) return

    this.element.scrollLeft = current.offsetLeft - (this.element.clientWidth - current.offsetWidth) / 2
  }
}
