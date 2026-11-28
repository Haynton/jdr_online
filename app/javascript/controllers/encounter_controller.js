import { Controller } from "@hotwired/stimulus"

// The panel « Rencontre » of the game master (game_rooms/panels/_encounter): the creatures added, how many of each, their
// experience points added up and the difficulty they make, compared with the budget of each difficulty worked out by
// the server (EncounterBudget). Nothing is saved: a tool to prepare an encounter
export default class extends Controller {
  static targets = ["chosen", "empty", "summary", "total", "verdict", "line"]
  static values = { difficulties: Array, above: String, difficulty: String }

  connect() {
    this.counts = new Map()
    this.format = new Intl.NumberFormat(document.documentElement.lang || undefined)
  }

  add(event) {
    const { key, name, xp } = event.currentTarget.dataset
    const current = this.counts.get(key) || { name, xp: Number(xp), count: 0 }
    this.counts.set(key, { ...current, count: current.count + 1 })
    this.render()
  }

  addAgain(event) {
    this.change(event, 1)
  }

  remove(event) {
    this.change(event, -1)
  }

  change(event, step) {
    const key = event.currentTarget.closest("li").dataset.key
    const current = this.counts.get(key)
    if (current.count + step <= 0) this.counts.delete(key)
    else this.counts.set(key, { ...current, count: current.count + step })
    this.render()
  }

  render() {
    this.chosenTarget.replaceChildren(...[...this.counts].map(([key, creature]) => this.lineFor(key, creature)))
    const total = [...this.counts.values()].reduce((sum, creature) => sum + creature.xp * creature.count, 0)
    this.emptyTarget.hidden = this.counts.size > 0
    this.summaryTarget.hidden = this.counts.size === 0
    this.totalTarget.textContent = `${this.format.format(total)} XP`
    this.verdictTarget.textContent = this.verdict(total)
  }

  lineFor(key, creature) {
    const line = this.lineTarget.content.firstElementChild.cloneNode(true)
    line.dataset.key = key
    line.querySelector("[data-encounter-line=name]").textContent = creature.name
    line.querySelector("[data-encounter-line=count]").textContent = creature.count
    line.querySelector("[data-encounter-line=xp]").textContent = `${this.format.format(creature.xp * creature.count)} XP`
    line.querySelector("[data-encounter-line=remove]").setAttribute("aria-label", `− ${creature.name}`)
    line.querySelector("[data-encounter-line=add]").setAttribute("aria-label", `+ ${creature.name}`)
    return line
  }

  // The first difficulty whose budget the total stays within, or beyond the last one
  verdict(total) {
    const reached = this.difficultiesValue.find((difficulty) => total <= difficulty.budget)
    return reached ? `${this.difficultyValue} ${reached.label}` : this.aboveValue
  }
}
