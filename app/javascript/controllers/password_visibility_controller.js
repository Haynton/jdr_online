import { Controller } from "@hotwired/stimulus"

// Shows or hides what is typed in a password field (see app/inputs/password_input.rb).
// The button is rendered hidden: it only appears once this controller runs, so that it never does nothing.
export default class extends Controller {
  static targets = ["field", "button", "showIcon", "hideIcon"]

  connect() {
    this.buttonTarget.hidden = false
  }

  toggle() {
    this.setPasswordVisible(this.fieldTarget.type === "password")
  }

  // Called when any form is sent: a password sent as plain text could be kept in the browser's history of typed values
  hide() {
    this.setPasswordVisible(false)
  }

  setPasswordVisible(isVisible) {
    this.fieldTarget.type = isVisible ? "text" : "password"
    this.buttonTarget.setAttribute("aria-pressed", String(isVisible))
    this.showIconTarget.hidden = isVisible
    this.hideIconTarget.hidden = !isVisible
  }
}
