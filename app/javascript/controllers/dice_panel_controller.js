import { Controller } from "@hotwired/stimulus"

// The panel « Dés » of the game room: a mode of the template (advantage) rolls a single die of its sides, so its
// options are greyed out as soon as another die or more than one die is chosen, and « Normal » is chosen back. The
// server refuses such a roll anyway; without JavaScript, the modes stay open
export default class extends Controller {
  static targets = ["side", "count", "mode", "normalMode"]
  static values = { modesOnSides: Number }

  connect() {
    this.updateModes()
  }

  updateModes() {
    if (!this.hasNormalModeTarget) return

    const modesApply = this.countTarget.value === "1" && this.chosenSides() === this.modesOnSidesValue
    this.modeTargets.forEach((mode) => {
      mode.disabled = !modesApply
      if (!modesApply && mode.checked) this.normalModeTarget.checked = true
    })
  }

  chosenSides() {
    const chosen = this.sideTargets.find((side) => side.checked)
    return chosen ? Number(chosen.value) : null
  }
}
