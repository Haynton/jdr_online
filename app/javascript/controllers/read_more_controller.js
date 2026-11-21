import { Controller } from "@hotwired/stimulus"

// A long text cut after a few lines, with a button that shows it all, then folds it again.
// The controller only sets data-clamped on the text, whose classes cut it (data-clamped:line-clamp-3): without
// JavaScript, the text stays whole, since the button would do nothing. The button is rendered hidden and shown
// only when the text is really cut (a short text needs none)
export default class extends Controller {
  static targets = ["text", "button"]
  static values = { moreLabel: String, lessLabel: String }

  connect() {
    this.textTarget.toggleAttribute("data-clamped", true)
    if (this.isCut()) {
      this.buttonTarget.hidden = false
    } else {
      this.textTarget.toggleAttribute("data-clamped", false)
    }
  }

  toggle() {
    const isClamped = this.textTarget.toggleAttribute("data-clamped")
    this.buttonTarget.setAttribute("aria-expanded", !isClamped)
    this.buttonTarget.textContent = isClamped ? this.moreLabelValue : this.lessLabelValue
  }

  isCut() {
    return this.textTarget.scrollHeight > this.textTarget.clientHeight
  }
}
