import { Controller } from "@hotwired/stimulus"

// Filters the table cards of "My tables" with pills (role: GM or player, status: draft or in progress),
// in the browser: every card is already on the page. Within a group, the pressed values add up;
// between the groups, they combine. A group with no pressed pill lets every card through.
// The pills are rendered hidden: without JavaScript they would do nothing, and every table stays in view.
// A user with no table gets no pills at all (nothing to filter)
export default class extends Controller {
  static targets = ["pills", "pill", "card", "noMatch"]

  connect() {
    if (this.hasPillsTarget) this.pillsTarget.hidden = false
  }

  toggle(event) {
    const pill = event.currentTarget
    pill.setAttribute("aria-pressed", String(pill.getAttribute("aria-pressed") !== "true"))
    this.showMatchingCards()
  }

  showMatchingCards() {
    const chosenValues = this.chosenValuesByGroup()
    this.cardTargets.forEach((card) => {
      card.hidden = !this.isMatching(card, chosenValues)
    })
    this.noMatchTarget.hidden = this.cardTargets.some((card) => !card.hidden)
    // The row has changed length: card_row_controller.js updates its arrows
    this.dispatch("changed")
  }

  // { role: ["game_master"], status: [] }: the values of the pressed pills, by group
  chosenValuesByGroup() {
    return this.pillTargets.reduce((chosenValues, pill) => {
      const { group, value } = pill.dataset
      chosenValues[group] ||= []
      if (pill.getAttribute("aria-pressed") === "true") chosenValues[group].push(value)
      return chosenValues
    }, {})
  }

  isMatching(card, chosenValues) {
    return Object.entries(chosenValues).every(([group, values]) => {
      return values.length === 0 || values.includes(card.dataset[group])
    })
  }
}
