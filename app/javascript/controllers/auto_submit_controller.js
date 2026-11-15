import { Controller } from "@hotwired/stimulus"

// Sends its form as soon as one of its fields changes, without a submit button
// (the language of the display settings). The row description tells the user beforehand
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
