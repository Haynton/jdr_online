import { Controller } from "@hotwired/stimulus"

// The skills to pick on the sheet of the creation (character_sheets/sections/_rows), when the table limits them: a skill
// the options picked do not offer is faded and its box disabled (data-off); once the count is reached, so are the other
// skills offered (data-full), until one is unticked. What is offered and how many come from character_sheet_controller.js
// (data-offered on each line, data-allowed on the count), which runs on the same change: read after it. The server
// checks the count again (CharacterSkillChoicesValidator)
export default class extends Controller {
  static targets = ["row", "count"]
  static values = { limited: Boolean }

  connect() {
    this.refresh()
  }

  refresh() {
    requestAnimationFrame(() => this.fadeWhatCannotBePicked())
  }

  fadeWhatCannotBePicked() {
    const choiceRows = this.rowTargets.filter((row) => row.dataset.state === "choice")
    const offeredRows = choiceRows.filter((row) => row.hasAttribute("data-offered"))
    const picked = offeredRows.filter((row) => this.boxOf(row).checked).length
    const full = this.limitedValue && this.hasCountTarget && picked >= Number(this.countTarget.dataset.allowed ?? 0)
    choiceRows.forEach((row) => {
      const box = this.boxOf(row)
      const off = this.limitedValue && !row.hasAttribute("data-offered")
      const faded = !off && full && !box.checked
      row.toggleAttribute("data-off", off)
      row.toggleAttribute("data-full", faded)
      box.disabled = off || faded
    })
  }

  boxOf(row) {
    return row.querySelector("input[type=checkbox][value='1']")
  }
}
