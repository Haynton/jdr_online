import { Controller } from "@hotwired/stimulus"

// The point buy on the abilities step: counts the points spent on the scores typed, while the player types ("12 points
// spent out of 27"), in red past the points (data-invalid). A score shows the bonus of the background placed on it
// (character_sheet_controller.js, data-shown-bonus): the cost is the one of the score typed, without it. The server
// counts again and refuses more points (AbilityMethods::PointBuy)
export default class extends Controller {
  static targets = ["status"]
  static values = { costs: Object, points: Number, template: String }

  count() {
    if (!this.hasStatusTarget) return

    const spent = this.scoreInputs().reduce((total, input) => total + this.costOf(input), 0)
    this.statusTarget.textContent = this.templateValue.replace("%{spent}", spent).replace("%{points}", this.pointsValue)
    this.statusTarget.toggleAttribute("data-invalid", spent > this.pointsValue)
  }

  scoreInputs() {
    return Array.from(this.element.querySelectorAll("input[data-character-sheet-target~='score']"))
  }

  // A score outside the costs counts nothing here: its tile shows the error once the step is sent
  costOf(input) {
    const shownScore = Number.parseInt(input.value, 10)
    if (Number.isNaN(shownScore)) return 0

    const typedScore = shownScore - Number(input.dataset.shownBonus ?? 0)
    return this.costsValue[typedScore] ?? 0
  }
}
