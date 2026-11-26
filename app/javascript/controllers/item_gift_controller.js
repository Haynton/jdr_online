import { Controller } from "@hotwired/stimulus"

// « Donner » in the panel « Objets » of the game room (game_rooms/panels/_items): each item's button opens the window
// of the gift (game_rooms/_item_gift_dialog) for that item, its name in the title and its key in the form; the
// window takes the focus itself. The buttons are rendered hidden and shown here: without JavaScript, no window opens
export default class extends Controller {
  static targets = ["opener", "dialog", "title", "key"]
  static values = { title: String }

  connect() {
    this.openerTargets.forEach((opener) => { opener.hidden = false })
  }

  open(event) {
    this.opener = event.currentTarget
    this.keyTarget.value = event.params.key
    this.titleTarget.textContent = this.titleValue.replace("__ITEM__", event.params.name)
    this.dialogTarget.showModal()
    this.dialogTarget.focus()
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
