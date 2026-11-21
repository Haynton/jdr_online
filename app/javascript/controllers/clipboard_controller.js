import { Controller } from "@hotwired/stimulus"

// Copies a text (the invitation link) with one click, and says so in a live region read by screen readers.
// The button is rendered hidden: it only appears once this controller runs, so that it never does nothing.
// Without it, the link stays in a read-only field, selected as a whole on focus, to copy by hand
export default class extends Controller {
  static targets = ["source", "button", "status"]
  static values = { copiedText: String, failedText: String }

  connect() {
    this.buttonTarget.hidden = false
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.statusTarget.textContent = this.copiedTextValue
    } catch {
      this.selectAll()
      this.statusTarget.textContent = this.failedTextValue
    }
  }

  selectAll() {
    this.sourceTarget.select()
  }
}
