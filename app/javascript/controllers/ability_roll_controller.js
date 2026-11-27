import { Controller } from "@hotwired/stimulus"

// "Roll the dice" of the abilities on the character sheet. The server rolls (AbilityRollsController, never the
// browser) and answers with one result per ability; they show as tokens in the tray (chipTemplate), which
// ability_tokens_controller.js places on the cards (a "?" per ability until then; a new roll empties the scores). The player can still roll again or type their own scores when the
// table allows it (decision: an aid, not a check). Rendered hidden and shown here: nothing without JavaScript. The standard array uses it too, given its values (preset) instead of rolling them:
// offered from the start, nothing to roll (the server checks each value is placed once, AbilityMethods::StandardArray)
export default class extends Controller {
  static targets = ["controls", "button", "buttonLabel", "results", "chipTemplate", "afterRoll"]
  static values = { url: String, rerollLabel: String, preset: Array, rolled: Array,
                    rerolls: { type: Boolean, default: true } }

  connect() {
    if (this.hasControlsTarget) this.controlsTarget.hidden = false
    this.rolledResults = []
    if (this.presetValue.length > 0) this.showResults(this.presetValue.map((total) => ({ total, dice: [] })))
    if (this.rolledValue.length > 0) this.showRoll(this.rolledValue)
    else if (this.presetValue.length === 0) this.resultsTarget.hidden = false
  }

  async roll() {
    this.buttonTarget.disabled = true
    try {
      const response = await fetch(this.urlValue, { method: "POST", headers: requestHeaders() })
      if (!response.ok) return

      const { results, final } = await response.json()
      this.rerollsValue = !final
      this.showRoll(results)
      this.dispatch("rolled")
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  // The results of a roll, new or kept by the server (rolled); « Relancer » while a roll is left (rerolls: none when
  // the table turns rolls again off, one only when it allows them), gone after (the server gives the roll kept back)
  showRoll(results) {
    this.showResults(results)
    this.buttonLabelTarget.textContent = this.rerollLabelValue
    // The wrapper hides: on the button, its inline-flex class wins over the hidden attribute
    if (!this.rerollsValue && this.hasControlsTarget) this.controlsTarget.hidden = true
  }

  // One token per result, its dice as its tooltip; the tokens of the tray start again from them
  showResults(results) {
    this.rolledResults = results
    const tokens = results.map(({ total, dice }, index) => {
      const token = this.chipTemplateTarget.content.firstElementChild.cloneNode(true)
      token.querySelector("[data-total]").textContent = total
      token.dataset.index = `${index}`
      token.dataset.total = `${total}`
      if (dice.length > 0) token.title = dice.join(", ")
      return token
    })
    this.resultsTarget.replaceChildren(...tokens)
    this.resultsTarget.hidden = false
    if (this.hasAfterRollTarget) this.afterRollTarget.hidden = false
  }
}

function requestHeaders() {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
  return { Accept: "application/json", "X-CSRF-Token": csrfToken }
}
