import { Controller } from "@hotwired/stimulus"

// A zone to drop a file on, around a file field: the file is sent as soon as it is dropped or chosen, its form
// submitted (no button to press). While a file is dragged over it, the zone says so (data-dragging); while it is sent,
// its message says it (sendingLabel). Without JavaScript, the field and the submit button of the form remain
export default class extends Controller {
  static targets = ["input", "status", "submit"]
  static values = { sendingLabel: String }

  connect() {
    this.hideSubmit()
  }

  // Also after a refresh by morphing (the picture sent comes back with the page), which puts back the page as the
  // server drew it without connecting again
  hideSubmit() {
    if (this.hasSubmitTarget) this.submitTarget.hidden = true
  }

  // dragenter and dragover: without preventing them, the browser would open the file in the tab
  showDragging(event) {
    event.preventDefault()
    this.element.dataset.dragging = ""
  }

  hideDragging(event) {
    if (this.element.contains(event.relatedTarget)) return

    delete this.element.dataset.dragging
  }

  drop(event) {
    event.preventDefault()
    delete this.element.dataset.dragging
    const files = event.dataTransfer?.files
    if (!files?.length) return

    this.inputTarget.files = files
    this.send()
  }

  send() {
    if (!this.inputTarget.files.length) return

    if (this.hasStatusTarget) this.statusTarget.textContent = this.sendingLabelValue
    this.inputTarget.form.requestSubmit()
  }
}
