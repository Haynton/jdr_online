import { Controller } from "@hotwired/stimulus"

// What serves in a fight on the card of one fighter (game_rooms/_fighter_status): its hit points changed by − and +,
// its conditions added from their window and removed by a click. The same card is
// in a quick sheet of the strip of the fighters and in the panel « Ma fiche », which is out of the strip: it tells the
// strip by events (the ring of the portrait, the window of the conditions, combat_strip_controller.js). Nothing is
// saved, nothing reaches the others: it all stays in this page
export default class extends Controller {
  static targets = ["hitPoints", "bar", "conditions"]
  static values = { groupKey: String, name: String }

  changeHitPoints(event) {
    const max = Number(this.hitPointsTarget.dataset.max)
    const current = Math.min(Math.max(Number(this.hitPointsTarget.textContent) + event.params.delta, 0), max)
    const percent = Math.round((100 * current) / max)
    this.hitPointsTarget.textContent = current
    this.barTarget.style.width = `${percent}%`
    this.dispatch("hit-points", { detail: { groupKey: this.groupKeyValue, percent } })
  }

  // The window of the conditions belongs to the strip: it adds the condition picked to this card
  openConditions(event) {
    this.dispatch("open-conditions", {
      detail: { name: this.nameValue, list: this.conditionsTarget, opener: event.currentTarget }
    })
  }

  removeCondition(event) {
    event.currentTarget.remove()
  }
}
