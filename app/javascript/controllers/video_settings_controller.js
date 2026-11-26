import { Controller } from "@hotwired/stimulus"
import { VIDEO_KEYS, VIDEO_SIZES, readVideoSetting, writeVideoSetting } from "controllers/video_island_controller"

// The cameras in the settings of the game (game_rooms/settings/_video): shown or not, and their size, the same
// choices as the buttons of their island (video_island_controller.js), kept in this browser; both follow
// game-room-video:change. The lines are rendered hidden and shown here
export default class extends Controller {
  static targets = ["line", "switch", "size"]

  connect() {
    this.lineTargets.forEach((line) => { line.hidden = false })
    this.refresh()
  }

  showCameras(event) {
    writeVideoSetting(VIDEO_KEYS.hidden, event.detail.checked ? null : "true")
  }

  chooseSize(event) {
    const size = event.params.size
    writeVideoSetting(VIDEO_KEYS.size, size === VIDEO_SIZES[0] ? null : size)
  }

  refresh() {
    const savedSize = readVideoSetting(VIDEO_KEYS.size)
    const size = VIDEO_SIZES.includes(savedSize) ? savedSize : VIDEO_SIZES[0]
    this.sizeTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.videoSettingsSizeParam === size))
    })
    const shown = readVideoSetting(VIDEO_KEYS.hidden) !== "true"
    this.switchTarget.querySelector("[role=switch]").setAttribute("aria-checked", String(shown))
  }
}
