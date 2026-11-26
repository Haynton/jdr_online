import { Controller } from "@hotwired/stimulus"

// « Déplier la barre au survol », in the display of the settings of the game (game_rooms/settings/_display): kept in
// this browser (localStorage, key game_room_toolbar_hover, "off" when turned off; a convenience of each viewer). It
// sets data-hover-off on the bar of tools (#game-room-toolbar), whose classes then never unfold it on hover
// (GameRoomToolbarHelper); the keyboard still does. Rendered hidden and shown here: without JavaScript there is no hover
// to turn off
const STORAGE_KEY = "game_room_toolbar_hover"

export default class extends Controller {
  static targets = ["switch"]

  connect() {
    this.element.hidden = false
    const hoverOn = this.read() !== "off"
    this.switchTarget.querySelector("[role=switch]").setAttribute("aria-checked", String(hoverOn))
    this.apply(hoverOn)
  }

  change(event) {
    const hoverOn = event.detail.checked
    this.apply(hoverOn)
    this.write(hoverOn)
  }

  apply(hoverOn) {
    document.getElementById("game-room-toolbar")?.toggleAttribute("data-hover-off", !hoverOn)
  }

  // Storage can be blocked (private window): the bar still unfolds, only the room forgets the choice
  read() {
    try {
      return localStorage.getItem(STORAGE_KEY)
    } catch {
      return null
    }
  }

  write(hoverOn) {
    try {
      if (hoverOn) {
        localStorage.removeItem(STORAGE_KEY)
      } else {
        localStorage.setItem(STORAGE_KEY, "off")
      }
    } catch {
      // Nothing to do: the bar unfolds on hover next time
    }
  }
}
