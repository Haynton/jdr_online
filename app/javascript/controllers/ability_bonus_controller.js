import { Controller } from "@hotwired/stimulus"

// The bonus of the background on the abilities step: each ability it raises has a choice of +0, +1 or +2 (choice
// targets, radio buttons). The guide says what is left to place, that it is done (+2 and +1, or +1 to each: 3 in
// all), or that there is too much (+2 twice, more than 3), then in red (data-invalid). An aid: the server checks the
// same rule (CharacterSheetValidator). The status is rendered by the server and kept up to date here
export default class extends Controller {
  static targets = ["choice", "status"]
  static values = { leftOne: String, leftOther: String, done: String, tooMany: String }

  update() {
    if (!this.hasStatusTarget) return

    const bonuses = this.choiceTargets.filter((choice) => choice.checked).map((choice) => Number(choice.value))
    const total = bonuses.reduce((sum, bonus) => sum + bonus, 0)
    const doubleCount = bonuses.filter((bonus) => bonus === 2).length
    this.statusTarget.textContent = this.statusText(total, doubleCount)
    this.statusTarget.toggleAttribute("data-invalid", total > 3 || doubleCount > 1)
  }

  statusText(total, doubleCount) {
    if (total > 3 || doubleCount > 1) return this.tooManyValue
    if (total === 3) return this.doneValue

    const left = 3 - total
    return left === 1 ? this.leftOneValue : this.leftOtherValue.replace("%{count}", left)
  }
}
