import { Controller } from "@hotwired/stimulus"

// The cameras of the game room (game_rooms/_video): three sizes, made smaller or larger by the buttons of the pill
// under them, opened in the middle, folded (a single button « Visio » unfolds them; it also stands for the line when
// it has no room, and then opens the call in the middle), and shown or not from the settings
// (game_rooms/settings/_video). All kept in this browser (localStorage: a convenience of each viewer), and told to each
// other by the event game-room-video:change on window, so that the cameras and the settings always agree. Without
// JavaScript, the cameras stay small and unfolded, without their buttons
export const VIDEO_SIZES = ["small", "medium", "large"]
export const VIDEO_KEYS = {
  size: "game_room_video_size", folded: "game_room_video_folded", hidden: "game_room_video_hidden",
  stage: "game_room_video_stage"
}
// Under this width, a place would be under 60 px high (16:9): the line folds by itself (decision)
const SMALLEST_PLACE_WIDTH = 107
const PLACES_GAP = 8
// The room kept on each side of the line for the islands at the top (max-w-[calc(100%-40rem)])
const ROOM_FOR_THE_ISLANDS = 640

export function readVideoSetting(key) {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

export function writeVideoSetting(key, value) {
  try {
    if (value) {
      localStorage.setItem(key, value)
    } else {
      localStorage.removeItem(key)
    }
  } catch {
    // Storage blocked (private window): the choice lasts until the page is left
  }
  window.dispatchEvent(new CustomEvent("game-room-video:change"))
}

export default class extends Controller {
  static targets = ["controls", "smaller", "larger", "places", "unfold"]

  connect() {
    this.refresh()
  }

  smaller() {
    this.changeSize(-1)
  }

  larger() {
    this.changeSize(1)
  }

  changeSize(step) {
    const index = Math.min(Math.max(VIDEO_SIZES.indexOf(this.size) + step, 0), VIDEO_SIZES.length - 1)
    writeVideoSetting(VIDEO_KEYS.size, index === 0 ? null : VIDEO_SIZES[index])
  }

  toggle() {
    writeVideoSetting(VIDEO_KEYS.folded, this.folded ? null : "true")
  }

  // « Visio »: back from folded; when the line has no room, the call opens in the middle instead
  unfold() {
    if (this.cramped) {
      this.enterStage()
    } else {
      writeVideoSetting(VIDEO_KEYS.folded, null)
    }
  }

  enterStage() {
    writeVideoSetting(VIDEO_KEYS.stage, "true")
  }

  // « Revenir en haut », or Escape while the call is in the middle (a window open above keeps its own Escape)
  leaveStage(event) {
    if (!this.stage || (event?.type === "keydown" && document.querySelector("dialog[open]"))) return

    writeVideoSetting(VIDEO_KEYS.stage, null)
  }

  // Reads the choices kept in this browser and shows them
  refresh() {
    const savedSize = readVideoSetting(VIDEO_KEYS.size)
    this.size = VIDEO_SIZES.includes(savedSize) ? savedSize : VIDEO_SIZES[0]
    this.folded = readVideoSetting(VIDEO_KEYS.folded) === "true"
    this.stage = readVideoSetting(VIDEO_KEYS.stage) === "true"
    this.cramped = this.lineHasNoRoom()
    const shownAsButton = !this.stage && (this.folded || this.cramped)
    this.element.dataset.size = this.stage ? "stage" : this.size
    this.element.hidden = readVideoSetting(VIDEO_KEYS.hidden) === "true"
    this.placesTarget.hidden = shownAsButton
    this.controlsTarget.hidden = shownAsButton
    this.unfoldTarget.hidden = !shownAsButton
    this.smallerTarget.disabled = this.size === VIDEO_SIZES[0]
    this.largerTarget.disabled = this.size === VIDEO_SIZES.at(-1)
  }

  // The places at their smallest (60 px high) do not fit between the islands at the top
  lineHasNoRoom() {
    const count = this.placesTarget.children.length
    const needed = count * SMALLEST_PLACE_WIDTH + (count - 1) * PLACES_GAP
    return needed > window.innerWidth - ROOM_FOR_THE_ISLANDS
  }
}
