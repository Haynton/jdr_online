import { Controller } from "@hotwired/stimulus"

// The bonus of the background on the abilities step: each ability it raises has a choice of +0 up to maxPerAbility
// (choice targets, radio buttons). The guide says what is left to place of the total, that it is done, or that there
// is too much (more than the total, or more than maxPerAbility on one ability), then in red (data-invalid). Same rule
// as FieldTypes::AbilityBonuses#too_much?, read from the field of the template; the server checks it
// (CharacterSheetValidator). The status is rendered by the server and kept up to date here
export default class extends Controller {
  static targets = ["choice", "status"]
  static values = { total: Number, maxPerAbility: Number, leftOne: String, leftOther: String, done: String,
    tooMany: String }

  update() {
    if (!this.hasStatusTarget) return

    const bonuses = this.choiceTargets.filter((choice) => choice.checked).map((choice) => Number(choice.value))
    const placed = bonuses.reduce((sum, bonus) => sum + bonus, 0)
    const isTooMuch = placed > this.totalValue || bonuses.some((bonus) => bonus > this.maxPerAbilityValue)
    this.statusTarget.textContent = this.statusText(placed, isTooMuch)
    this.statusTarget.toggleAttribute("data-invalid", isTooMuch)
  }

  statusText(placed, isTooMuch) {
    if (isTooMuch) return this.tooManyValue
    if (placed === this.totalValue) return this.doneValue

    const left = this.totalValue - placed
    return left === 1 ? this.leftOneValue : this.leftOtherValue.replace("%{count}", left)
  }
}
