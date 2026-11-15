import { Controller } from "@hotwired/stimulus"

// Turns a role="switch" button on or off, then tells the page with a "switch:change" event.
// What the switch controls (a setting, the theme) listens to that event: this controller stays generic.
// The button is native, so Space and Enter already trigger the click.
export default class extends Controller {
  toggle() {
    const isChecked = this.element.getAttribute("aria-checked") !== "true"
    this.element.setAttribute("aria-checked", String(isChecked))
    this.dispatch("change", { detail: { checked: isChecked } })
  }
}
