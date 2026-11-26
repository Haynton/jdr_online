import { Controller } from "@hotwired/stimulus"
import { confirmWithDialog } from "confirm_dialog"

// The strip of the fighters of the game room (game_rooms/_combat_strip): « Lancer un combat » opens the
// preparation (the initiative rolled meanwhile), « Prêt » puts the strip in the order of initiative with its rounds,
// « Fin du combat » back to everyone without an order. A portrait opens its
// quick sheet above the strip (one at a time; Escape or a click elsewhere closes it), « Tour suivant » moves the gold
// ring to the next place and counts the rounds, − and + change the hit points of a fighter, a condition is added
// from its window and removed by a click on it. Nothing is saved, nothing reaches the others: it all stays in this
// page
export default class extends Controller {
  static targets = [
    "portrait", "sheet", "ring", "round", "order", "startButton", "preparationButtons", "fightButtons", "conditionChip",
    "conditionsDialog", "conditionsTitle"
  ]
  static values = {
    roundText: String, conditionsTitle: String, waitingOne: String, waitingOther: String, rolled: String
  }

  connect() {
    this.round = 1
  }

  disconnect() {
    this.stopRolls()
  }

  // « Lancer un combat » opens the preparation: the game master sets the board while the table rolls its initiative
  // (simulated here: the NPCs and the enemies at once, as the server will, each player a moment after the other,
  // their portraits faded until then); the creatures stay hidden from the players (data-preparing) until « Prêt »
  startFight() {
    this.element.setAttribute("data-preparing", "")
    this.showCreatures(true)
    this.startButtonTarget.hidden = true
    this.preparationButtonsTarget.hidden = false
    const players = this.orderTarget.querySelectorAll("[data-side=player] [data-combat-strip-target=portrait]")
    players.forEach((portrait) => portrait.setAttribute("data-waiting", ""))
    this.showWaiting()
    this.rollTimers = [...players].map((portrait, index) => {
      const delay = 900 + index * 900 + Math.random() * 600
      return setTimeout(() => this.playerRolled(portrait), delay)
    })
  }

  playerRolled(portrait) {
    portrait.removeAttribute("data-waiting")
    this.showWaiting()
  }

  waitingCount() {
    return this.orderTarget.querySelectorAll("[data-waiting]").length
  }

  showWaiting() {
    const count = this.waitingCount()
    let text = this.rolledValue
    if (count === 1) text = this.waitingOneValue
    if (count > 1) text = this.waitingOtherValue.replace("__COUNT__", count)
    this.roundTarget.textContent = text
    this.roundTarget.hidden = false
  }

  // « Prêt »: the creatures show to the players and the fight begins; a player who has not rolled yet is rolled for
  ready() {
    this.beginFight()
  }

  // « Annuler »: back out of a fight, nothing begun
  cancelPreparation() {
    this.leaveFight()
  }

  // The fight begins (everyone has rolled, or « Commencer sans attendre »): the order of initiative, round 1, the
  // first in it ringed in gold
  beginFight() {
    this.stopRolls()
    this.element.removeAttribute("data-preparing")
    this.portraitTargets.forEach((portrait) => portrait.removeAttribute("data-waiting"))
    this.sortPortraits("initiativeRank")
    this.round = 1
    this.roundTarget.textContent = this.roundTextValue.replace("__ROUND__", this.round)
    this.portraitTargets.forEach((portrait, index) => portrait.toggleAttribute("data-current", index === 0))
    this.showCurrent(this.portraitTargets[0])
    this.preparationButtonsTarget.hidden = true
    this.fightButtonsTarget.hidden = false
  }

  stopRolls() {
    this.rollTimers?.forEach((timer) => clearTimeout(timer))
    this.rollTimers = []
  }

  // « Fin du combat », asked first in the confirmation window: the strip stays
  async endFight(event) {
    const button = event.currentTarget
    if (await confirmWithDialog(button.dataset.confirmQuestion, button)) this.leaveFight()
  }

  // Out of a fight: everyone back in their resting order, without turns
  leaveFight() {
    this.stopRolls()
    this.element.removeAttribute("data-preparing")
    this.portraitTargets.forEach((portrait) => portrait.removeAttribute("data-waiting"))
    this.sortPortraits("restRank")
    this.showCreatures(false)
    this.roundTarget.hidden = true
    this.portraitTargets.forEach((portrait) => portrait.removeAttribute("data-current"))
    this.orderTarget.scrollTo({ left: 0 })
    this.preparationButtonsTarget.hidden = true
    this.fightButtonsTarget.hidden = true
    this.startButtonTarget.hidden = false
  }

  // Out of a fight, the strip shows the players alone; the NPCs and the enemies join it at the preparation
  showCreatures(shown) {
    this.orderTarget.querySelectorAll("li:not([data-side=player])").forEach((place) => { place.hidden = !shown })
  }

  sortPortraits(rank) {
    const places = [...this.orderTarget.children]
    places.sort((first, second) => Number(first.dataset[rank]) - Number(second.dataset[rank]))
    this.orderTarget.append(...places)
  }

  toggleSheet(event) {
    const key = event.currentTarget.dataset.groupKey
    const sheet = this.sheetTargets.find((candidate) => candidate.dataset.groupKey === key)
    const opening = sheet.hidden
    this.closeSheets()
    if (!opening) return

    sheet.hidden = false
    event.currentTarget.setAttribute("aria-expanded", "true")
  }

  closeSheets() {
    if (this.hasConditionsDialogTarget && this.conditionsDialogTarget.open) return

    this.sheetTargets.forEach((sheet) => { sheet.hidden = true })
    this.portraitTargets.forEach((portrait) => {
      if (portrait.hasAttribute("aria-expanded")) portrait.setAttribute("aria-expanded", "false")
    })
  }

  closeOnOutsideClick(event) {
    if (this.hasConditionsDialogTarget && this.conditionsDialogTarget.open) return
    if (!this.element.contains(event.target)) this.closeSheets()
  }

  nextTurn() {
    const current = this.portraitTargets.findIndex((portrait) => portrait.hasAttribute("data-current"))
    const next = (current + 1) % this.portraitTargets.length
    this.portraitTargets.forEach((portrait, index) => portrait.toggleAttribute("data-current", index === next))
    this.showCurrent(this.portraitTargets[next])
    if (next !== 0) return

    this.round += 1
    this.roundTarget.textContent = this.roundTextValue.replace("__ROUND__", this.round)
  }

  // On a narrow screen the portraits scroll: the one whose turn it is is brought into view, in the middle
  showCurrent(portrait) {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const list = portrait.closest("ol")
    const offset = portrait.getBoundingClientRect().left - list.getBoundingClientRect().left
    const left = list.scrollLeft + offset - (list.clientWidth - portrait.offsetWidth) / 2
    list.scrollTo({ left, behavior: reducedMotion ? "auto" : "smooth" })
  }

  changeHitPoints(event) {
    const member = event.currentTarget.closest("[data-combat-member]")
    const hitPoints = member.querySelector("[data-combat-hit-points]")
    const max = Number(hitPoints.dataset.max)
    const current = Math.min(Math.max(Number(hitPoints.textContent) + event.params.delta, 0), max)
    hitPoints.textContent = current
    member.querySelector("[data-combat-bar]").style.width = `${Math.round((100 * current) / max)}%`
    this.updateRing(member.dataset.groupKey)
  }

  // The ring of a place shows what is left of the hit points of all its fighters
  updateRing(groupKey) {
    const values = [...this.element.querySelectorAll(`[data-combat-member][data-group-key="${groupKey}"] [data-combat-hit-points]`)]
    const current = values.reduce((sum, value) => sum + Number(value.textContent), 0)
    const max = values.reduce((sum, value) => sum + Number(value.dataset.max), 0)
    const ring = this.ringTargets.find((candidate) => candidate.dataset.groupKey === groupKey)
    if (ring && max > 0) ring.style.strokeDasharray = `${Math.round((100 * current) / max)} 100`
  }

  // « Ajouter un état »: the window of the conditions, for the fighter of this sheet; it takes the focus itself
  openConditions(event) {
    this.conditionsList = event.currentTarget.closest("[data-combat-conditions]").querySelector("[data-combat-condition-chips]")
    this.conditionsOpener = event.currentTarget
    this.conditionsTitleTarget.textContent = this.conditionsTitleValue.replace("__NAME__", event.params.name)
    this.conditionsDialogTarget.showModal()
    this.conditionsDialogTarget.focus()
  }

  // Under the button, in the order they were added
  pickCondition(event) {
    const chip = this.conditionChipTarget.content.firstElementChild.cloneNode(true)
    chip.textContent = event.params.label
    chip.title = event.params.description || ""
    this.conditionsList.append(chip)
    this.closeConditions()
  }

  closeConditions() {
    this.conditionsDialogTarget.close()
    this.conditionsOpener?.focus({ focusVisible: false })
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeConditionsOnBackdrop(event) {
    if (event.target === this.conditionsDialogTarget) this.closeConditions()
  }

  // A spell slot ticked once used, unticked when it comes back
  toggleSlot(event) {
    const slot = event.currentTarget
    slot.setAttribute("aria-pressed", String(slot.getAttribute("aria-pressed") !== "true"))
  }

  removeCondition(event) {
    event.currentTarget.remove()
  }
}
