import { Controller } from "@hotwired/stimulus"

// The window of a level gained (game_tables/level_ups/new): what each subclass brings to pick (its skills, its groups of
// choices) is prepared by the server, hidden; the block of the subclass picked in the list shows at once, and the
// fields of the others are turned off, so that only its choices are sent (decision of 27 November: no second sending
// of the window). Without JavaScript, the block of the subclass picked shows when the window comes back
export default class extends Controller {
  static targets = ["select", "block"]

  connect() {
    this.show()
  }

  show() {
    const picked = this.hasSelectTarget ? this.selectTarget.value : ""
    this.blockTargets.forEach((block) => {
      const shown = block.dataset.subclass === picked
      block.hidden = !shown
      block.querySelectorAll("input, select, textarea").forEach((field) => { field.disabled = !shown })
    })
  }
}
