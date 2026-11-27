import { Controller } from "@hotwired/stimulus"

// Lists drawn as cards (character_sheets/sections/_option_cards): the card picked is a radio button, sent with the
// form. The page reads a list in its field of the usual id (the effects, the calculation, the summary of the option,
// the lists that depend on it): the hidden mirror of its list takes the option picked and sends a change, which they
// follow as they followed the select
export default class extends Controller {
  static targets = ["mirror"]

  // The mirror of the list of the card (data-field-key: several lists may share the section)
  pick({ target: radio }) {
    const mirror = this.mirrorTargets.find((field) => field.dataset.fieldKey === radio.dataset.fieldKey)
    if (!mirror || mirror.value === radio.value) return

    mirror.value = radio.value
    mirror.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
