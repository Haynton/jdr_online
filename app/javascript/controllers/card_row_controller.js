import { Controller } from "@hotwired/stimulus"

const reducedMotionQuery = "(prefers-reduced-motion: reduce)"
// One click moves the row by most of its visible width: the last card seen stays in view
const scrollShare = 0.8

// Moves a row that scrolls sideways (the table cards of "My tables") with two arrow buttons.
// The buttons are rendered hidden: without JavaScript they would do nothing, and the row still scrolls
export default class extends Controller {
  static targets = ["row", "previousButton", "nextButton"]

  connect() {
    this.previousButtonTarget.hidden = false
    this.nextButtonTarget.hidden = false
    this.revealChosenCard()
    this.toggleButtons()
  }

  scrollPrevious() {
    this.scrollRow(-1)
  }

  scrollNext() {
    this.scrollRow(1)
  }

  // An arrow is disabled at its end of the row
  toggleButtons() {
    const { scrollLeft, scrollWidth, clientWidth } = this.rowTarget
    this.previousButtonTarget.disabled = scrollLeft <= 0
    this.nextButtonTarget.disabled = scrollLeft + clientWidth >= scrollWidth - 1
  }

  scrollRow(direction) {
    const isMotionReduced = window.matchMedia(reducedMotionQuery).matches
    this.rowTarget.scrollBy({
      left: direction * this.rowTarget.clientWidth * scrollShare,
      behavior: isMotionReduced ? "auto" : "smooth"
    })
  }

  // Choosing a card reloads the page: without this, the row would start again from its first card
  revealChosenCard() {
    const chosenCard = this.rowTarget.querySelector("[aria-current=true]")
    if (!chosenCard) return

    const cardCenter = chosenCard.offsetLeft - this.rowTarget.offsetLeft + chosenCard.offsetWidth / 2
    this.rowTarget.scrollLeft = cardCenter - this.rowTarget.clientWidth / 2
  }
}
