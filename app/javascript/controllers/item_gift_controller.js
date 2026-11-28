import { Controller } from "@hotwired/stimulus"

// « Donner » in the panel « Objets » of the game room (game_rooms/panels/_items): each item's button opens the window
// of the gift (game_rooms/_item_gift_dialog) for that item, its name in the title and its key in the form; the
// window takes the focus itself. For a weapon, an armour, a shield or ammunition (kind), the list « Magie » keeps only
// the magic that goes on that item (its kind, and its keys when it names some); for another item it stays hidden. The
// buttons are rendered hidden and shown here: without JavaScript, no window opens
export default class extends Controller {
  static targets = ["opener", "dialog", "title", "key", "magic", "enchantment"]
  static values = { title: String }

  connect() {
    this.openerTargets.forEach((opener) => { opener.hidden = false })
  }

  open(event) {
    this.opener = event.currentTarget
    this.keyTarget.value = event.params.key
    this.titleTarget.textContent = this.titleValue.replace("__ITEM__", event.params.name)
    this.offerMagic(event.params.kind, event.params.key)
    this.dialogTarget.showModal()
    this.dialogTarget.focus()
  }

  offerMagic(kind, key) {
    if (!this.hasEnchantmentTarget) return

    let fitting = 0
    Array.from(this.enchantmentTarget.options).forEach((option) => {
      if (option.value === "") return

      const keys = option.dataset.keys ? option.dataset.keys.split(" ") : []
      option.hidden = !kind || option.dataset.appliesTo !== kind || (keys.length > 0 && !keys.includes(key))
      option.disabled = option.hidden
      if (!option.hidden) fitting += 1
    })
    this.enchantmentTarget.value = ""
    this.magicTarget.hidden = fitting === 0
  }

  close() {
    this.dialogTarget.close()
    this.opener?.focus({ focusVisible: false })
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
