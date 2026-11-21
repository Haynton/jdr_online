import { Controller } from "@hotwired/stimulus"

// A sticky band that leaves room to read: it slides away while the page scrolls down and comes back as soon as it
// scrolls up. Near the top of the page, and while the keyboard focus is inside it, it always shows.
// The controller only sets data-scrolled-away; the classes of the element slide it (data-scrolled-away:)
// A few pixels of scrolling are ignored, so that a trembling finger or a trackpad does not make it blink
const scrollThreshold = 8

export default class extends Controller {
  static values = { alwaysShownUntil: { type: Number, default: 120 } }

  connect() {
    this.lastScrollY = window.scrollY
  }

  update() {
    const scrollDistance = window.scrollY - this.lastScrollY
    if (Math.abs(scrollDistance) < scrollThreshold) return

    this.lastScrollY = window.scrollY
    this.toggle(scrollDistance > 0 && window.scrollY > this.alwaysShownUntilValue)
  }

  show() {
    this.toggle(false)
  }

  toggle(isScrolledAway) {
    const hasFocusInside = this.element.contains(document.activeElement)
    this.element.toggleAttribute("data-scrolled-away", isScrolledAway && !hasFocusInside)
  }
}
