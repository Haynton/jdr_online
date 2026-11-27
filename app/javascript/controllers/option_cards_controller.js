import { Controller } from "@hotwired/stimulus"

// A list drawn as cards (character_sheets/sections/_option_cards): the card picked is a radio button, sent with the
// form. The page reads a list in its field of the usual id (the effects, the calculation, the summary of the option,
// the lists that depend on it): this hidden mirror takes the option picked and sends a change, which they follow as
// they followed the select
export default class extends Controller {
  static targets = ["mirror"]

  pick({ target: radio }) {
    if (!this.hasMirrorTarget || this.mirrorTarget.value === radio.value) return

    this.mirrorTarget.value = radio.value
    this.mirrorTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
