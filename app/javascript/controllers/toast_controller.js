import { Controller } from "@hotwired/stimulus"

// A message floating above the page (shared/_toast), like a notification: closed by its button, or leaves by itself
// after its duration (longer for an error, MessagesHelper). The countdown pauses while the pointer or the keyboard
// focus is on it, so that it never leaves while being read. Removed before Turbo keeps the page in its cache, so that
// going back to the page does not show it again
const LEAVING_DURATION_IN_MILLISECONDS = 200

export default class extends Controller {
  static targets = ["closeButton"]
  static values = { duration: Number }

  connect() {
    this.closeButtonTarget.hidden = false
    this.removeBeforeCache = () => this.element.remove()
    document.addEventListener("turbo:before-cache", this.removeBeforeCache)

    this.remainingTime = this.durationValue
    this.resume()
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.removeBeforeCache)
    clearTimeout(this.closeTimer)
  }

  // Both the pointer and the focus may pause it: only the first one stops a running countdown
  pause() {
    if (!this.closeTimer) return

    clearTimeout(this.closeTimer)
    this.closeTimer = null
    this.remainingTime -= Date.now() - this.countdownStartedAt
  }

  // Waits while the other one (pointer or focus) is still on it
  resume() {
    if (this.closeTimer || this.element.matches(":hover, :focus-within")) return

    this.countdownStartedAt = Date.now()
    this.closeTimer = setTimeout(() => this.close(), this.remainingTime)
  }

  // Fades out first (data-leaving), unless the device asks for less motion
  close() {
    clearTimeout(this.closeTimer)
    const leavingDuration = this.asksForLessMotion ? 0 : LEAVING_DURATION_IN_MILLISECONDS

    this.element.dataset.leaving = ""
    setTimeout(() => this.element.remove(), leavingDuration)
  }

  get asksForLessMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
