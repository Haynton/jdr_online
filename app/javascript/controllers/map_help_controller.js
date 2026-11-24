import { Controller } from "@hotwired/stimulus"

// The help of the map editor, in a bubble beside its round button over the board (Anthony's request): open by itself
// the first time this browser opens the editor, then only from its button. It closes with its cross, Escape, its
// button again, or a click anywhere else (drawing on the board, choosing a tool). The editor of a map of a table has
// its own help (its tokens, its blocked zones), seen apart: open by itself the first time too (storageKey). Rendered
// hidden: shown here
const seenValue = "seen"

export default class extends Controller {
  static targets = ["button", "bubble"]
  static values = { storageKey: { type: String, default: "map_editor_help" } }

  connect() {
    this.element.hidden = false
    if (this.alreadySeen()) return

    this.open()
    this.rememberSeen()
  }

  // After a refresh by morphing, which puts back the page as the server drew it (hidden) without connecting again
  reveal() {
    this.element.hidden = false
  }

  toggle() {
    this.bubbleTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.bubbleTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.bubbleTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeWithEscape(event) {
    if (event.key === "Escape" && !this.bubbleTarget.hidden) this.close()
  }

  // A click elsewhere puts the help away (drawing, choosing a tool); a click in the bubble or on its button does not
  closeFromOutside(event) {
    if (this.bubbleTarget.hidden || this.element.contains(event.target)) return

    this.close()
  }

  // The storage may be blocked (private window, site data refused): the help then opens each time, nothing breaks
  alreadySeen() {
    try {
      return window.localStorage.getItem(this.storageKeyValue) === seenValue
    } catch {
      return false
    }
  }

  rememberSeen() {
    try {
      window.localStorage.setItem(this.storageKeyValue, seenValue)
    } catch {
      // Nothing kept: the help opens again next time
    }
  }
}
