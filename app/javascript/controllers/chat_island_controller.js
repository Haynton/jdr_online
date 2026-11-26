import { Controller } from "@hotwired/stimulus"

// The chat of the game room (game_rooms/_chat): low by default, its height changed by the handle at its top (dragged,
// or the arrow keys, Shift for a bigger step) and folded by its button. Both are kept in this browser
// (localStorage, a convenience of each viewer: the room opens as it was left). The handle and the button are rendered
// hidden and shown here: without JavaScript, the chat keeps its height. « Afficher le chat » in the settings of the game
// hides it altogether (chat_visibility_controller.js, the same key, told by game-room-chat:change on window)
const HEIGHT_KEY = "game_room_chat_height"
const FOLDED_KEY = "game_room_chat_folded"
export const HIDDEN_KEY = "game_room_chat_hidden"
const MIN_HEIGHT = 160
const KEY_STEP = 24
const BIG_KEY_STEP = 96

export default class extends Controller {
  static targets = ["handle", "toggle", "body"]
  static values = { foldLabel: String, unfoldLabel: String }

  connect() {
    this.handleTarget.hidden = false
    this.toggleTarget.hidden = false
    const savedHeight = Number(this.read(HEIGHT_KEY))
    if (savedHeight) this.setHeight(savedHeight)
    this.element.setAttribute("data-chat-island-ready", "")
    this.setFolded(this.read(FOLDED_KEY) === "true")
    this.showOrHide()
  }

  showOrHide() {
    this.element.hidden = this.read(HIDDEN_KEY) === "true"
  }

  toggle() {
    this.setFolded(!this.folded)
    this.write(FOLDED_KEY, this.folded ? "true" : null)
  }

  startResize(event) {
    if (event.button !== 0) return

    event.preventDefault()
    const startY = event.clientY
    const startHeight = this.bodyTarget.offsetHeight
    if (this.folded) this.setFolded(false)
    const resize = (moveEvent) => this.setHeight(startHeight + startY - moveEvent.clientY)
    const stop = () => {
      window.removeEventListener("pointermove", resize)
      window.removeEventListener("pointerup", stop)
      this.saveHeight()
    }
    window.addEventListener("pointermove", resize)
    window.addEventListener("pointerup", stop)
  }

  resizeWithKeys(event) {
    const step = event.shiftKey ? BIG_KEY_STEP : KEY_STEP
    const changes = { ArrowUp: step, ArrowDown: -step }
    if (!(event.key in changes)) return

    event.preventDefault()
    if (this.folded) this.setFolded(false)
    this.setHeight(this.bodyTarget.offsetHeight + changes[event.key])
    this.saveHeight()
  }

  // Never under the header of the room, never so low that nothing of the chat shows
  setHeight(height) {
    const maxHeight = Math.round(window.innerHeight * 0.7)
    const shownHeight = Math.min(Math.max(height, MIN_HEIGHT), maxHeight)
    this.bodyTarget.style.height = `${shownHeight}px`
    this.handleTarget.setAttribute("aria-valuenow", String(shownHeight))
    this.handleTarget.setAttribute("aria-valuemin", String(MIN_HEIGHT))
    this.handleTarget.setAttribute("aria-valuemax", String(maxHeight))
  }

  setFolded(folded) {
    this.folded = folded
    this.bodyTarget.hidden = folded
    this.handleTarget.hidden = folded
    this.toggleTarget.setAttribute("aria-expanded", String(!folded))
    const label = folded ? this.unfoldLabelValue : this.foldLabelValue
    this.toggleTarget.setAttribute("aria-label", label)
    this.toggleTarget.title = label
    // The feed counts what comes while the chat is folded (chat_feed_controller.js, on the same element)
    this.dispatch("folded", { detail: { folded } })
  }

  saveHeight() {
    this.write(HEIGHT_KEY, String(this.bodyTarget.offsetHeight))
  }

  // Storage can be blocked (private window): the chat still works, only the room forgets how it was left
  read(key) {
    try {
      return localStorage.getItem(key)
    } catch {
      return null
    }
  }

  write(key, value) {
    try {
      if (value) {
        localStorage.setItem(key, value)
      } else {
        localStorage.removeItem(key)
      }
    } catch {
      // Nothing to do: the chat opens as it is by default next time
    }
  }
}
