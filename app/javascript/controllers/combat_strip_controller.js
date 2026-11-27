import { Controller } from "@hotwired/stimulus"
import { confirmWithDialog } from "confirm_dialog"

// The strip of the fighters of the game room (game_rooms/_combat_strip): « Lancer le tour par tour » asks whether the
// table rolls its initiative, then opens the preparation; « Prêt » begins the turns (in the order of initiative, or
// the one of the strip without a roll), which the game master may reorder (asked first); « Fin du tour par tour »
// brings everyone back without an order. A portrait opens its quick sheet above the strip (one at a time; Escape or a
// click elsewhere closes it), « Tour suivant » moves the gold ring to the next place and counts the rounds. The hit
// points of a fighter, changed on its card (fighter_card_controller.js), redraw the ring of its portrait, and a
// condition is added to a card from the window of the conditions. The order of initiative comes from the rolls of the
// panel « Dés »: after each one, the server sends the new ranks to the game master (ranksTargetConnected), which
// « Prêt » sorts by; an order already begun is never shuffled. The rest is not saved, nothing reaches the others: it
// all stays in this page
export default class extends Controller {
  static targets = [
    "portrait", "sheet", "ring", "round", "order", "startButton", "startDialog", "preparationButtons", "fightButtons",
    "conditionChip", "conditionsDialog", "conditionsTitle", "ranks"
  ]
  static values = {
    roundText: String, conditionsTitle: String, waitingOne: String, waitingOther: String, rolled: String,
    preparing: String, reorderQuestion: String, reorderButton: String, reorderable: Boolean, portraitLabel: String
  }

  connect() {
    this.round = 1
  }

  disconnect() {
    this.stopRolls()
  }

  // The ranks sent after a roll of initiative (replaced on the stream of the game master): each place takes its new
  // rank, each portrait the initiative it says to screen readers
  ranksTargetConnected(template) {
    const ranks = JSON.parse(template.dataset.ranks)
    this.portraitTargets.forEach((portrait) => {
      const rank = ranks[portrait.dataset.groupKey]
      if (!rank) return

      portrait.closest("li").dataset.initiativeRank = rank.rank
      if (!portrait.dataset.fighterName) return

      const label = this.portraitLabelValue
        .replace("__NAME__", portrait.dataset.fighterName).replace("__INITIATIVE__", rank.initiative)
      portrait.setAttribute("aria-label", label)
      portrait.title = label
    })
  }

  // « Lancer le tour par tour » first asks whether the whole table rolls its initiative; the window takes the focus
  askInitiative() {
    this.startDialogTarget.showModal()
    this.startDialogTarget.focus()
  }

  closeStartDialog() {
    this.startDialogTarget.close()
  }

  closeStartDialogOnBackdrop(event) {
    if (event.target === this.startDialogTarget) this.closeStartDialog()
  }

  // With a roll: the preparation while the table rolls (simulated here: the NPCs and the enemies at once, as the
  // server will, each player a moment after the other, their portraits faded until then)
  startWithRolls() {
    this.closeStartDialog()
    this.withRolls = true
    this.openPreparation()
    const players = this.orderTarget.querySelectorAll("[data-side=player] [data-combat-strip-target=portrait]")
    players.forEach((portrait) => portrait.setAttribute("data-waiting", ""))
    this.showWaiting()
    this.rollTimers = [...players].map((portrait, index) => {
      const delay = 900 + index * 900 + Math.random() * 600
      return setTimeout(() => this.playerRolled(portrait), delay)
    })
  }

  // Without a roll: the preparation alone, the order the one of the strip, which the game master may change
  startWithoutRolls() {
    this.closeStartDialog()
    this.withRolls = false
    this.openPreparation()
    this.setReorderable(true)
    this.roundTarget.textContent = this.preparingValue
    this.roundTarget.hidden = false
  }

  // The game master sets the board; the creatures join the strip, hidden from the players (data-preparing) until
  // « Prêt »
  openPreparation() {
    this.element.setAttribute("data-preparing", "")
    this.showCreatures(true)
    this.startButtonTarget.hidden = true
    this.preparationButtonsTarget.hidden = false
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

  // « Prêt »: the creatures show to the players and the turns begin; a player who has not rolled yet is rolled for
  ready() {
    this.beginFight()
  }

  // « Annuler »: back out of the turns, nothing begun
  cancelPreparation() {
    this.leaveFight()
  }

  // The turns begin: the order of initiative (or the one of the strip, without a roll), round 1, the first in it
  // ringed in gold; the game master may now change the order
  beginFight() {
    this.stopRolls()
    this.element.removeAttribute("data-preparing")
    this.portraitTargets.forEach((portrait) => portrait.removeAttribute("data-waiting"))
    if (this.withRolls) this.sortPortraits("initiativeRank")
    this.setReorderable(true)
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

  // « Fin du tour par tour », asked first in the confirmation window: the strip stays
  async endFight(event) {
    const button = event.currentTarget
    if (await confirmWithDialog(button.dataset.confirmQuestion, button)) this.leaveFight()
  }

  // Out of the turns: everyone back in their resting order, without turns
  leaveFight() {
    this.stopRolls()
    this.setReorderable(false)
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

  // During the turns (and from the preparation without a roll), the game master drags a place of the strip with the
  // mouse or a finger, or moves it with Alt and an arrow. A drag made by hand rather than the native drag and drop:
  // a portrait is a button, from which a browser starts no native drag
  setReorderable(reorderable) {
    this.reordering = reorderable && this.reorderableValue
    this.element.toggleAttribute("data-reordering", this.reordering)
  }

  pointerDown(event) {
    if (!this.reordering || event.button !== 0) return

    const place = event.target.closest("li")
    if (!place) return

    this.pressed = { place, startX: event.clientX }
    this.followPointer = (moveEvent) => this.pointerMove(moveEvent)
    this.releasePointer = () => this.pointerUp()
    window.addEventListener("pointermove", this.followPointer)
    window.addEventListener("pointerup", this.releasePointer, { once: true })
  }

  // Past 6 px, the press becomes a drag: the place follows the pointer among the others, by their middle
  pointerMove(event) {
    const { place, startX } = this.pressed
    if (!this.dragged) {
      if (Math.abs(event.clientX - startX) < 6) return

      this.dragged = place
      this.orderBefore = [...this.orderTarget.children]
      place.setAttribute("data-dragged", "")
    }
    const other = document.elementFromPoint(event.clientX, event.clientY)?.closest("li")
    if (!other || other === place || other.parentNode !== this.orderTarget) return

    const box = other.getBoundingClientRect()
    this.orderTarget.insertBefore(place, event.clientX < box.left + box.width / 2 ? other : other.nextSibling)
  }

  pointerUp() {
    window.removeEventListener("pointermove", this.followPointer)
    if (!this.dragged) return

    this.dragged.removeAttribute("data-dragged")
    this.dragged = null
    // The release ends the drag: it must not open the quick sheet of the portrait
    this.draggedJustNow = true
    setTimeout(() => { this.draggedJustNow = false }, 0)
    this.confirmNewOrder()
  }

  moveWithKeys(event) {
    if (!this.reordering || !event.altKey || !["ArrowLeft", "ArrowRight"].includes(event.key)) return

    event.preventDefault()
    const place = event.currentTarget.closest("li")
    this.orderBefore = [...this.orderTarget.children]
    const neighbour = event.key === "ArrowLeft" ? place.previousElementSibling : place.nextElementSibling
    if (!neighbour) return

    if (event.key === "ArrowLeft") neighbour.before(place)
    else neighbour.after(place)
    event.currentTarget.focus()
    this.confirmNewOrder(event.currentTarget)
  }

  // The new order is asked first; refused, the order before comes back
  async confirmNewOrder(focused = null) {
    const changed = this.orderBefore.some((place, index) => this.orderTarget.children[index] !== place)
    if (!changed) return

    const confirmed = await confirmWithDialog(this.reorderQuestionValue, { dataset: { confirmButton: this.reorderButtonValue } })
    if (!confirmed) this.orderTarget.append(...this.orderBefore)
    focused?.focus()
  }

  sortPortraits(rank) {
    const places = [...this.orderTarget.children]
    places.sort((first, second) => Number(first.dataset[rank]) - Number(second.dataset[rank]))
    this.orderTarget.append(...places)
  }

  toggleSheet(event) {
    if (this.draggedJustNow) return

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
    // A condition just removed by this click is no longer in the page: not a click elsewhere
    if (!event.target.isConnected) return
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

  // The hit points of a fighter changed on its card (fighter_card_controller.js, in a quick sheet or the panel
  // « Ma fiche »): the ring of its portrait shows what is left of them
  updateRing({ detail: { groupKey, percent } }) {
    const ring = this.ringTargets.find((candidate) => candidate.dataset.groupKey === groupKey)
    if (ring) ring.style.strokeDasharray = `${percent} 100`
  }

  // « Ajouter un état » on the card of a fighter: the window of the conditions, for that fighter; it takes the focus
  openConditions({ detail: { name, list, opener } }) {
    this.conditionsList = list
    this.conditionsOpener = opener
    this.conditionsTitleTarget.textContent = this.conditionsTitleValue.replace("__NAME__", name)
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
}
