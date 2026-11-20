import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// The settings window (shared/_settings_dialog): a native <dialog> around the Turbo Frame "settings_dialog".
// It opens once a section has loaded into the frame, and closes with Escape (native), its close button
// or a click beside it. Closed, the frame is emptied: the next "Settings" loads the section again, up to date
// (a frame does not reload an address it already shows)
export default class extends Controller {
  static targets = ["frame"]

  // showModal focuses the first button, the close cross: the window takes the focus itself instead
  open() {
    if (this.element.open) return

    this.element.showModal()
    this.element.focus()
  }

  close() {
    if (this.element.open) this.element.close()
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  // The language changed inside the window shows there at once; the page behind it still speaks the old one
  // and reloads once the window is closed
  closed() {
    const languageChanged = this.hasChangedLanguage()
    this.empty()
    if (languageChanged) Turbo.visit(window.location.href, { action: "replace" })
  }

  // The settings carry their language (lang of layouts/settings); the page carries its own on <html>
  hasChangedLanguage() {
    const settings = this.frameTarget.querySelector("[data-settings-language]")
    return settings !== null && settings.lang !== document.documentElement.lang
  }

  empty() {
    this.frameTarget.removeAttribute("src")
    this.frameTarget.replaceChildren()
  }
}
