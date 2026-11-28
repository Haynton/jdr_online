import { Controller } from "@hotwired/stimulus"

// The big card of a spell at the Spells step (game_tables/character_steps/_spell_card_dialog): « Lire la carte » copies
// the face of its card (its <template data-spell-card-big>) into the window, with the tone of its school, and the
// button at the foot ticks or unticks the box of the card, which the hand follows (spell_hand_controller.js, on
// change). A native <dialog>: Escape closes it; the focus goes back to the link, without a ring after a click
// (as details_dialog_controller.js). The links are rendered hidden and shown here: nothing to open without JavaScript
export default class extends Controller {
  static targets = ["opener", "dialog", "face", "body", "toggle"]

  openerTargetConnected(opener) {
    opener.hidden = false
  }

  open({ currentTarget: opener }) {
    this.opener = opener
    this.card = opener.closest("li")
    this.faceTarget.style.setProperty("--tone", getComputedStyle(this.card).getPropertyValue("--tone"))
    this.bodyTarget.replaceChildren(this.card.querySelector("template[data-spell-card-big]").content.cloneNode(true))
    this.showToggle()
    this.dialogTarget.showModal()
    // showModal focuses the first button, the cross: the window takes the focus itself instead
    this.dialogTarget.focus()
  }

  // The box of the card ticked or unticked as a click on the card would: the change reaches the hand
  toggle() {
    const box = this.cardBox()
    if (box.disabled) return

    box.click()
    this.showToggle()
  }

  // « Mettre dans ma main », « Retirer de ma main », or disabled: the hand of its group full, a spell given already.
  // A card of the spellbook says it writes the spell in the book (its own labels on the card)
  showToggle() {
    const box = this.cardBox()
    const labels = { ...this.dialogTarget.dataset, ...this.card.dataset }
    const toggle = this.toggleTarget
    toggle.disabled = box.disabled
    toggle.className = box.checked ? labels.dropClasses : labels.takeClasses
    if (box.disabled) toggle.textContent = box.checked ? labels.givenLabel : labels.fullLabel
    else toggle.textContent = box.checked ? labels.dropLabel : labels.takeLabel
  }

  cardBox() {
    return this.card.querySelector("[data-card-box]")
  }

  close(event) {
    if (!this.dialogTarget.open) return

    if (event?.detail === 0) this.closedWithKeyboard = true
    this.dialogTarget.close()
  }

  cancelled() {
    this.closedWithKeyboard = true
  }

  // The focus back on « Lire la carte », its ring only after the keyboard (data-focus-quiet, application.css)
  returnFocus() {
    if (!this.opener?.isConnected) return

    if (!this.closedWithKeyboard) this.quietFocusRing(this.opener)
    this.opener.focus({ focusVisible: Boolean(this.closedWithKeyboard) })
    this.closedWithKeyboard = false
  }

  quietFocusRing(element) {
    element.setAttribute("data-focus-quiet", "")
    const showRingAgain = () => {
      element.removeAttribute("data-focus-quiet")
      element.removeEventListener("blur", showRingAgain)
      element.removeEventListener("keydown", showRingAgain)
    }
    element.addEventListener("blur", showRingAgain)
    element.addEventListener("keydown", showRingAgain)
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
