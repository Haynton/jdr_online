import { Controller } from "@hotwired/stimulus"

const reducedMotionQuery = "(prefers-reduced-motion: reduce)"
// One click moves the row by most of its visible width: the last card seen stays in view
const scrollShare = 0.8

// The row of table cards of "My tables": two arrow buttons move it, and choosing a card marks it as the chosen one.
// The arrows are rendered hidden: without JavaScript they would do nothing, and the row still scrolls
export default class extends Controller {
  static targets = ["row", "previousButton", "nextButton"]

  connect() {
    this.previousButtonTarget.hidden = false
    this.nextButtonTarget.hidden = false
    this.revealChosenCard()
    this.toggleButtons()
  }

  // A card only replaces the chosen table above (Turbo Frame): the row stays as it is,
  // so the gold outline (aria-current) moves to the clicked card here
  choose(event) {
    this.rowTarget.querySelectorAll("[aria-current=true]").forEach((card) => card.removeAttribute("aria-current"))
    event.currentTarget.setAttribute("aria-current", "true")
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

  // Arriving on the page with ?table= (from a link, or back in the history): the chosen card is centered,
  // the row would otherwise start from its first card
  revealChosenCard() {
    const chosenCard = this.rowTarget.querySelector("[aria-current=true]")
    if (!chosenCard) return

    const cardCenter = chosenCard.offsetLeft - this.rowTarget.offsetLeft + chosenCard.offsetWidth / 2
    this.rowTarget.scrollLeft = cardCenter - this.rowTarget.clientWidth / 2
  }
}
