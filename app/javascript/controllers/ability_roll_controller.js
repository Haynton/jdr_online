import { Controller } from "@hotwired/stimulus"

// "Roll the dice" of the abilities on the character sheet. The server rolls (AbilityRollsController, never the
// browser) and answers with one result per ability; they show as chips (chipTemplate), and each ability tile offers
// them in its "Place a result" list. A result placed on one ability is no longer offered elsewhere. Placing a
// result only fills the score of the tile and tells the live calculation: the player can still change it, roll again,
// or type their own scores (decision: an aid, not a check). Rendered hidden and shown here: nothing without JavaScript
export default class extends Controller {
  static targets = ["controls", "button", "buttonLabel", "results", "chipTemplate", "choice"]
  static values = { url: String, rerollLabel: String, placeholder: String }

  connect() {
    this.controlsTarget.hidden = false
    this.rolledResults = []
  }

  async roll() {
    this.buttonTarget.disabled = true
    try {
      const response = await fetch(this.urlValue, { method: "POST", headers: requestHeaders() })
      if (!response.ok) return

      const { results } = await response.json()
      this.rolledResults = results
      this.showResults()
      this.offerResults()
      this.buttonLabelTarget.textContent = this.rerollLabelValue
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  // A result chosen in a tile goes into its score; the other lists stop offering it
  place(event) {
    const result = this.rolledResults[event.target.value]
    if (result) {
      const scoreInput = document.getElementById(event.target.dataset.scoreInput)
      scoreInput.value = result.total
      scoreInput.dispatchEvent(new Event("input", { bubbles: true }))
    }
    this.markPlacedResults()
  }

  showResults() {
    const chips = this.rolledResults.map(({ total, dice }) => {
      const chip = this.chipTemplateTarget.content.firstElementChild.cloneNode(true)
      chip.querySelector("[data-total]").textContent = total
      chip.querySelector("[data-dice]").textContent = `(${dice.join(", ")})`
      return chip
    })
    this.resultsTarget.replaceChildren(...chips)
    this.resultsTarget.hidden = false
  }

  // Every tile starts again from "Place a result" with all the new results
  offerResults() {
    this.choiceTargets.forEach((choice) => {
      const select = choice.querySelector("select")
      const options = this.rolledResults.map(({ total }, index) => new Option(`${total}`, index))
      select.replaceChildren(new Option(this.placeholderValue, ""), ...options)
      choice.hidden = false
    })
  }

  markPlacedResults() {
    const selects = this.choiceTargets.map((choice) => choice.querySelector("select"))
    const placedIndexes = selects.map((select) => select.value).filter((value) => value !== "")
    selects.forEach((select) => {
      Array.from(select.options).forEach((option) => {
        option.disabled = option.value !== "" && option.value !== select.value && placedIndexes.includes(option.value)
      })
    })
  }
}

function requestHeaders() {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
  return { Accept: "application/json", "X-CSRF-Token": csrfToken }
}
