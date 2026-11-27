import { Controller } from "@hotwired/stimulus"

// The help of a field in a bubble (CharacterSheets::HelpBubblesHelper): the help, rendered under the field, is turned
// into a bubble laid over the fields below (its classes in data-bubble-classes) and hidden; the button (i) after the
// label, rendered hidden, is shown and opens or closes it. Escape or a click elsewhere closes it, the focus back on
// the button after Escape. Without JavaScript, the help stays under the field
export default class extends Controller {
  static targets = ["button", "bubble"]

  connect() {
    if (!this.hasBubbleTarget || !this.hasButtonTarget) return

    this.element.classList.add("relative")
    this.bubbleTarget.classList.add(...this.bubbleTarget.dataset.bubbleClasses.split(" "))
    this.bubbleTarget.hidden = true
    this.buttonTarget.hidden = false
  }

  toggle() {
    this.show(this.bubbleTarget.hidden)
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || this.bubbleTarget.hidden) return

    event.preventDefault()
    event.stopPropagation()
    this.show(false)
    this.buttonTarget.focus()
  }

  closeOutside(event) {
    if (this.bubbleTarget.hidden || this.element.contains(event.target)) return

    this.show(false)
  }

  show(open) {
    this.bubbleTarget.hidden = !open
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}
