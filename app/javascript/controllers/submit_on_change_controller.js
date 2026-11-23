import { Controller } from "@hotwired/stimulus"

// Sends its form as soon as one of its controls changes, through a given submit button (the submitter target: on the
// step "Spells and items", the one that saves and stays on the tab shown), so that the server knows where to go next.
// With the page refreshed by morphing (turbo_refreshes_with), the list stays where it was. Without JavaScript, the
// buttons of the form save as usual
export default class extends Controller {
  static targets = ["submitter"]

  submit() {
    this.element.requestSubmit(this.submitterTarget)
  }
}
