import { Controller } from "@hotwired/stimulus"

// The tray of tokens of the abilities step (character_sheets/sections/_abilities): the player touches a token, then
// the card where it goes. A value (of the standard array, or rolled: ability_roll_controller.js renders them) fills the
// score of the card; a "+1" of the background adds one to the bonus of the card: two make +2, never more than the most
// of its rule (only on an ability the background raises: the others fade while a bonus is held). A token placed fades;
// placed again elsewhere, it leaves the card it was on. A point buy has a "+" and a "−" instead of values: held, they
// stay in hand, and each card touched goes up or down by one, between the lowest and the highest cost, within the points
// (an empty score counts as the lowest). "Start again" empties the scores and takes the bonus back. The tokens only fill the fields the step always
// sent: the live calculation (character_sheet_controller.js) and the server follow them as before
export default class extends Controller {
  static targets = ["valueToken", "bonusToken", "stepToken", "bonusTray", "card", "hint", "fallback"]
  static values = { idle: String, holdValue: String, holdBonus: String, maxPerAbility: Number,
                    costs: Object, points: Number, holdRaise: String, holdLower: String }

  connect() {
    this.held = null
    this.placedValues = {}
    this.placedBonuses = {}
    this.fallbackTargets.forEach((fallback) => { fallback.hidden = true })
    if (this.hasBonusTrayTarget) this.bonusTrayTarget.hidden = false
    this.readPlacedBonuses()
    this.refresh()
    this.element.addEventListener("ability-roll:rolled", () => this.takeValuesBack())
  }

  // A new roll: the scores of the roll before are emptied, the bonus stays
  takeValuesBack() {
    this.cardTargets.forEach((card) => this.writeScore(card, ""))
    this.placedValues = {}
    this.held = null
    this.refresh()
  }

  // The values rendered by ability_roll_controller.js: a new roll takes the values placed back
  valueTokenTargetConnected() {
    clearTimeout(this.readSoon)
    this.readSoon = setTimeout(() => {
      this.readPlacedValues()
      this.refresh()
    })
  }

  hold({ currentTarget: token }) {
    const same = this.held === token
    this.held = same ? null : token
    this.refresh()
  }

  // The card touched receives the token held
  place({ currentTarget: button }) {
    const card = button.closest("[data-ability-tokens-target='card']")
    if (!this.held || !this.mayReceive(card)) return

    // A "+" or a "−" stays in hand: the player touches every card to change
    if (this.held.dataset.kind === "step") {
      this.stepScore(card, Number(this.held.dataset.step))
      this.refresh()
      return
    }

    if (this.held.dataset.kind === "value") this.placeValue(card, this.held)
    else this.placeBonus(card, this.held)
    this.held = null
    this.refresh()
  }

  startAgain() {
    this.cardTargets.forEach((card) => {
      this.writeScore(card, "")
      this.writeBonus(card, 0)
    })
    this.placedValues = {}
    this.placedBonuses = {}
    this.held = null
    this.refresh()
  }

  // A value moved leaves its card empty
  placeValue(card, token) {
    Object.keys(this.placedValues).forEach((ability) => {
      if (this.placedValues[ability] !== token.dataset.index || ability === card.dataset.ability) return

      delete this.placedValues[ability]
      this.writeScore(this.cardOf(ability), "")
    })
    this.placedValues[card.dataset.ability] = token.dataset.index
    this.writeScore(card, Number(token.dataset.total))
  }

  // The bonus of a card is the number of "+1" on it (placedBonuses: token index → ability); a token moved leaves its card
  placeBonus(card, token) {
    const previousAbility = this.placedBonuses[token.dataset.index]
    this.placedBonuses[token.dataset.index] = card.dataset.ability
    if (previousAbility && previousAbility !== card.dataset.ability) {
      this.writeBonus(this.cardOf(previousAbility), this.bonusOn(previousAbility))
    }
    this.writeBonus(card, this.bonusOn(card.dataset.ability))
  }

  stepScore(card, step) {
    this.writeScore(card, this.typedScore(card) + step)
  }

  // The score of a card without the bonus shown in it; an empty one counts as the lowest cost (point buy)
  typedScore(card) {
    const input = document.getElementById(card.dataset.scoreInput)
    if (!input || input.value === "") return this.lowestScore()

    return Number(input.value) - Number(input.dataset.shownBonus ?? 0)
  }

  lowestScore() {
    return Math.min(...Object.keys(this.costsValue).map(Number))
  }

  // A score raised stays within the costs and the points; lowered, above the lowest (an empty one has nothing to lower)
  mayStep(card, step) {
    const input = document.getElementById(card.dataset.scoreInput)
    const score = this.typedScore(card)
    const next = score + step
    if (step < 0) return input?.value !== "" && next >= this.lowestScore()
    if (!(next in this.costsValue)) return false

    return this.pointsSpent() - (this.costsValue[score] ?? 0) + this.costsValue[next] <= this.pointsValue
  }

  pointsSpent() {
    return this.cardTargets.reduce((total, card) => {
      const input = document.getElementById(card.dataset.scoreInput)
      return input && input.value !== "" ? total + (this.costsValue[this.typedScore(card)] ?? 0) : total
    }, 0)
  }

  bonusOn(ability) {
    return Object.values(this.placedBonuses).filter((placedAbility) => placedAbility === ability).length
  }

  // The score shows the bonus placed on it (character_sheet_controller.js#showBonusInScore): the value goes in with it
  writeScore(card, total) {
    const input = document.getElementById(card.dataset.scoreInput)
    if (!input) return

    input.value = total === "" ? "" : total + Number(input.dataset.shownBonus ?? 0)
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  writeBonus(card, amount) {
    const choice = card?.querySelector(`input[type=radio][data-bonus="${amount}"]`)
    if (!choice || choice.checked) return

    choice.checked = true
    choice.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // A value goes on any card; a "+1" on an ability the background raises, while it holds less than the most
  mayReceive(card) {
    if (this.held?.dataset.kind === "value") return true
    if (this.held?.dataset.kind === "step") return this.mayStep(card, Number(this.held.dataset.step))
    if (!card.hasAttribute("data-raised")) return false

    const alreadyThere = this.placedBonuses[this.held.dataset.index] === card.dataset.ability
    return alreadyThere || this.bonusOn(card.dataset.ability) < this.maxPerAbilityValue
  }

  cardOf(ability) {
    return this.cardTargets.find((card) => card.dataset.ability === ability)
  }

  // The tokens placed: faded; the token held: raised; the cards that may receive it: ready, the others faded
  refresh() {
    const placedValueIndexes = Object.values(this.placedValues)
    const placedBonusIndexes = Object.keys(this.placedBonuses)
    this.valueTokenTargets.forEach((token) => {
      this.mark(token, placedValueIndexes.includes(token.dataset.index))
    })
    this.bonusTokenTargets.forEach((token) => {
      this.mark(token, placedBonusIndexes.includes(token.dataset.index))
    })
    this.stepTokenTargets.forEach((token) => this.mark(token, false))
    this.cardTargets.forEach((card) => {
      const ready = Boolean(this.held) && this.mayReceive(card)
      card.toggleAttribute("data-ready", ready)
      card.toggleAttribute("data-locked", Boolean(this.held) && !ready)
      card.querySelector("button[data-action~='ability-tokens#place']").disabled = !ready
    })
    this.writeHint()
  }

  mark(token, placed) {
    token.toggleAttribute("data-used", placed && token !== this.held)
    token.setAttribute("aria-pressed", `${token === this.held}`)
  }

  writeHint() {
    if (!this.hasHintTarget) return

    if (!this.held) this.hintTarget.textContent = this.idleValue
    else if (this.held.dataset.kind === "value") {
      this.hintTarget.textContent = this.holdValueValue.replace("__VALUE__", this.held.dataset.total)
    } else if (this.held.dataset.kind === "step") {
      this.hintTarget.textContent = this.held.dataset.step === "1" ? this.holdRaiseValue : this.holdLowerValue
    } else this.hintTarget.textContent = this.holdBonusValue
  }

  // The values already in the cards (a draft opened again): each score typed takes a token of the same total
  readPlacedValues() {
    this.placedValues = {}
    const free = [...this.valueTokenTargets]
    this.cardTargets.forEach((card) => {
      const input = document.getElementById(card.dataset.scoreInput)
      if (!input || input.value === "") return

      const typed = Number(input.value) - Number(input.dataset.shownBonus ?? 0)
      const token = free.find((candidate) => Number(candidate.dataset.total) === typed)
      if (!token) return

      free.splice(free.indexOf(token), 1)
      this.placedValues[card.dataset.ability] = token.dataset.index
    })
  }

  // The bonus already ticked (a draft opened again): a card at +2 takes two "+1"
  readPlacedBonuses() {
    this.placedBonuses = {}
    const free = [...this.bonusTokenTargets]
    this.cardTargets.forEach((card) => {
      const amount = Number(card.querySelector("input[type=radio]:checked")?.dataset.bonus ?? 0)
      free.splice(0, amount).forEach((token) => { this.placedBonuses[token.dataset.index] = card.dataset.ability })
    })
  }
}
