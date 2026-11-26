import { Controller } from "@hotwired/stimulus"

// The panel « Dés » of the game room: a mode of the template (advantage) rolls a single die, of any kind, so its
// options are greyed out as soon as more than one die is chosen, and « Normal » is chosen back. The server refuses
// such a roll anyway; without JavaScript, the modes stay open
export default class extends Controller {
  static targets = ["count", "mode", "normalMode"]

  connect() {
    this.updateModes()
  }

  updateModes() {
    if (!this.hasNormalModeTarget) return

    const modesApply = this.countTarget.value === "1"
    this.modeTargets.forEach((mode) => {
      mode.disabled = !modesApply
      if (!modesApply && mode.checked) this.normalModeTarget.checked = true
    })
  }
}
