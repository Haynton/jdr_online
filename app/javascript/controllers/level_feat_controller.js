import { Controller } from "@hotwired/stimulus"
import { modifierOf } from "modifier_rules"

// What a level of the step of the level feats shows as its points are placed (the tokens and the cards are those of
// the abilities step: ability_tokens_controller.js ticks the +0 | +1 | +2 of each card): on each card, its score and its
// modifier with its points, in gold once raised, « dont +2 ce niveau » under it, or that one point raises its modifier
// (an odd score the feat may raise); on the tab of the level, the feat picked and its points, its diamond in gold once
// every point is placed. Display only: the server checks the points (LevelUpFeat)
export default class extends Controller {
  static targets = ["feat", "card", "score", "modifier", "note"]
  static values = { level: Number, texts: Object }

  connect() {
    this.render()
  }

  render() {
    this.cardTargets.forEach((card) => this.renderCard(card))
    this.renderTab()
  }

  renderCard(card) {
    const points = this.pointsOn(card)
    const score = Number(card.dataset.before) + points
    card.toggleAttribute("data-gained", points > 0)
    card.querySelector("[data-level-feat-target='score']").textContent = score
    card.querySelector("[data-level-feat-target='modifier']").textContent = formatBonus(modifierOf(score, card.dataset.rule))
    const note = card.querySelector("[data-level-feat-target='note']")
    const gains = points === 0 && card.hasAttribute("data-raised") && score % 2 === 1
    note.textContent = points > 0 ? this.textsValue.placed.replace("__POINTS__", points) : (gains ? this.textsValue.gain : "")
    note.toggleAttribute("data-gain", points === 0)
  }

  // The points ticked on a card, its radio buttons sent (those of a feat not picked are turned off)
  pointsOn(card) {
    const checked = card.querySelector("input[type=radio]:checked:not(:disabled)")
    return Number(checked?.dataset.bonus ?? 0)
  }

  // The tab of the level: the feat picked and its points, its diamond in gold once complete
  renderTab() {
    const summary = document.querySelector(`[data-level-feat-summary="${this.levelValue}"]`)
    const mark = document.querySelector(`[data-level-feat-mark="${this.levelValue}"]`)
    const picked = this.featTargets.find((feat) => feat.checked)
    const name = picked?.closest("label")?.textContent.trim()
    const shownCards = this.cardTargets.filter((card) => !card.closest("[hidden]"))
    const placed = shownCards.reduce((total, card) => total + this.pointsOn(card), 0)
    const points = shownCards.filter((card) => this.pointsOn(card) > 0)
      .map((card) => `${card.querySelector("span").textContent.trim()} +${this.pointsOn(card)}`)
    if (summary && name) summary.textContent = [name, ...points].join(" · ")
    const total = Number(picked?.dataset.points || 0)
    mark?.toggleAttribute("data-complete", total === 0 || placed === total)
  }
}

// "+2", "-1", as CharacterSheets::ValuesHelper#format_bonus on the server
function formatBonus(value) {
  if (value === null) return "—"
  return value < 0 ? String(value) : `+${value}`
}
