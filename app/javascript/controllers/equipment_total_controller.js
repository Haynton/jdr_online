import { Controller } from "@hotwired/stimulus"

// The gold to start with on the Equipment step (game_tables/character_steps/_equipment_choices): the gold of the
// options checked in every block (each radio carries its own, data-gold), written again when one changes
export default class extends Controller {
  static targets = ["total"]
  static values = { template: String }

  count() {
    if (!this.hasTotalTarget) return

    const gold = Array.from(this.element.querySelectorAll("input[type=radio][data-gold]:checked"))
      .reduce((total, radio) => total + Number(radio.dataset.gold), 0)
    this.totalTarget.textContent = this.templateValue.replace("__GOLD__", gold)
  }
}
