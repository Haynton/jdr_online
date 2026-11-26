import { Controller } from "@hotwired/stimulus"
import { HIDDEN_KEY } from "controllers/chat_island_controller"

// « Afficher le chat », in the display of the settings of the game (game_rooms/settings/_display): hides the chat of the
// room altogether, kept in this browser (localStorage, a convenience of each viewer), told to the chat by the event
// game-room-chat:change on window. Rendered hidden and shown here: without JavaScript there is nothing to hide
export default class extends Controller {
  static targets = ["switch"]

  connect() {
    this.element.hidden = false
    this.switchTarget.querySelector("[role=switch]").setAttribute("aria-checked", String(this.read() !== "true"))
  }

  change(event) {
    try {
      if (event.detail.checked) {
        localStorage.removeItem(HIDDEN_KEY)
      } else {
        localStorage.setItem(HIDDEN_KEY, "true")
      }
    } catch {
      // Storage blocked (private window): the chat stays as it is
    }
    window.dispatchEvent(new CustomEvent("game-room-chat:change"))
  }

  read() {
    try {
      return localStorage.getItem(HIDDEN_KEY)
    } catch {
      return null
    }
  }
}
