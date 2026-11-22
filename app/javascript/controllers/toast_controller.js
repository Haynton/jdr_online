import { Controller } from "@hotwired/stimulus"

// A message floating above the page (shared/_toast): closed by its button, and a success message also leaves by
// itself once it has been read. Removed before Turbo keeps the page in its cache, so that going back to the page
// does not show it again
const AUTO_HIDE_DELAY_IN_MILLISECONDS = 6000

export default class extends Controller {
  static targets = ["closeButton"]
  static values = { autoHide: Boolean }

  connect() {
    this.closeButtonTarget.hidden = false
    this.closeBeforeCache = () => this.close()
    document.addEventListener("turbo:before-cache", this.closeBeforeCache)

    if (this.autoHideValue) {
      this.autoHideTimer = setTimeout(() => this.close(), AUTO_HIDE_DELAY_IN_MILLISECONDS)
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.closeBeforeCache)
    clearTimeout(this.autoHideTimer)
  }

  close() {
    this.element.remove()
  }
}
