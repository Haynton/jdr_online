import { Controller } from "@hotwired/stimulus"

// A number field between a "−" and a "+" button, which take it down or up by one, within its min and max.
// Nothing typed yet: "+" and "−" start from the min. After each step the field sends an input event, like typing,
// so that what follows it (the live calculation of a character sheet) updates. The buttons are rendered hidden
// and shown here: without JavaScript, the value is typed
export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    this.buttonTargets.forEach((button) => { button.hidden = false })
  }

  decrease() {
    this.step(-1)
  }

  increase() {
    this.step(1)
  }

  step(change) {
    const minimum = this.bound("min") ?? -Infinity
    const maximum = this.bound("max") ?? Infinity
    const current = Number.parseInt(this.inputTarget.value, 10)
    const next = Number.isNaN(current) ? Math.max(minimum, 0) : current + change
    this.inputTarget.value = Math.min(maximum, Math.max(minimum, next))
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  bound(attribute) {
    const value = Number.parseInt(this.inputTarget.getAttribute(attribute), 10)
    return Number.isNaN(value) ? null : value
  }
}
