import { Controller } from "@hotwired/stimulus"

// A list of boxes where only some may be ticked (the weapon masteries): writes how many are ticked in its count, and
// once enough are, disables the other boxes (their card fades, has-disabled), until one is unticked. The server checks
// the count again
export default class extends Controller {
  static targets = ["box", "count"]
  static values = { allowed: Number, template: String }

  connect() {
    this.count()
  }

  count() {
    const chosen = this.boxTargets.filter((box) => box.checked).length
    this.boxTargets.forEach((box) => { box.disabled = !box.checked && chosen >= this.allowedValue })
    if (!this.hasCountTarget) return

    this.countTarget.textContent = this.templateValue.replace("__CHOSEN__", chosen)
    this.countTarget.toggleAttribute("data-invalid", chosen > this.allowedValue)
  }
}
