import { Controller } from "@hotwired/stimulus"

// The panels of the game room (layouts/game_room): each tool of the bar (game_rooms/_toolbar) opens its panel beside it,
// one at a time; its tool again, the cross of the panel or Escape close it, and the focus goes back to the tool. The
// tools are links to their panel (#game-room-panel-…): without JavaScript the panel shows by :target; here, they
// become buttons (role, aria-expanded) and the panel shows by data-open, without changing the address.
// The open panel is remembered for this tab (sessionStorage, one key per table): saved from the panel (the rules, the
// language), the room comes back with it open
//
// « Paramètres », in the island at the top right (game_rooms/_top_bar), opens the window of the settings of the game
// (game_rooms/_settings_dialog), a native <dialog> (Escape, the cross or a click beside it close it). A section saved
// there brings back to the room on ?settings=…: the window opens again (settingsOpen), and the address loses that
// parameter once it is closed
export default class extends Controller {
  static targets = ["opener", "panel", "settingsOpener", "settingsDialog", "toolbar"]
  static values = { settingsOpen: Boolean }

  connect() {
    this.openerTargets.forEach((opener) => {
      opener.setAttribute("role", "button")
      opener.setAttribute("aria-expanded", "false")
    })
    const panelId = this.takeOverTargetedPanel() || this.rememberedPanelId()
    if (this.panelTargets.some((panel) => panel.id === panelId)) this.open(panelId, { focus: false })
    if (!this.hasSettingsOpenerTarget) return

    this.settingsOpenerTarget.hidden = false
    if (this.settingsOpenValue) this.openSettings()
  }

  // showModal focuses the first button, the cross: the window takes the focus itself instead
  openSettings() {
    if (this.settingsDialogTarget.open) return

    this.settingsDialogTarget.showModal()
    this.settingsDialogTarget.focus()
  }

  closeSettings() {
    if (this.settingsDialogTarget.open) this.settingsDialogTarget.close()
  }

  // A click on the backdrop reaches the <dialog> itself; a click inside lands on its content
  closeSettingsOnBackdrop(event) {
    if (event.target === this.settingsDialogTarget) this.closeSettings()
  }

  // Escape (the native cancel of the window): the focus goes back with its ring, the keyboard is in use
  settingsCancelled() {
    this.settingsClosedWithKeyboard = true
  }

  // The focus goes back to « Paramètres », its gold ring shown only after the keyboard (Escape): after a click on the
  // cross or beside the window, the ring looked like a selected button (Anthony's request)
  settingsClosed() {
    const address = new URL(window.location.href)
    if (address.searchParams.has("settings")) {
      address.searchParams.delete("settings")
      history.replaceState(history.state, "", address.pathname + address.search)
    }
    this.settingsOpenerTarget.focus({ focusVisible: Boolean(this.settingsClosedWithKeyboard) })
    this.settingsClosedWithKeyboard = false
  }

  toggle(event) {
    event.preventDefault()
    this.retractToolbar()
    const panelId = event.currentTarget.dataset.panelId
    this.usedOpener = event.currentTarget
    if (this.openPanelId === panelId) {
      this.close(event)
    } else {
      this.open(panelId)
    }
  }

  // A tool chosen folds the bar back over the board (its names would cover the panel just opened), until the mouse
  // leaves the bar: hovering it again unfolds it
  retractToolbar() {
    if (this.hasToolbarTarget) this.toolbarTarget.setAttribute("data-retracted", "")
  }

  releaseToolbar() {
    if (this.hasToolbarTarget) this.toolbarTarget.removeAttribute("data-retracted")
  }

  open(panelId, { focus = true } = {}) {
    this.openPanelId = panelId
    this.panelTargets.forEach((panel) => panel.toggleAttribute("data-open", panel.id === panelId))
    this.openerTargets.forEach((opener) => {
      opener.setAttribute("aria-expanded", String(opener.dataset.panelId === panelId))
    })
    this.remember(panelId)
    if (focus) this.panelTargets.find((panel) => panel.id === panelId)?.focus()
  }

  // Escape in a window (the settings, « Donner »...) belongs to the window (its native closing): the panel under it
  // stays open
  close(event) {
    if (!this.openPanelId || document.querySelector("dialog[open]")) return

    event?.preventDefault()
    // Back to what opened it: a panel may have two openers (« Ma fiche »: its tool, and the player's own portrait
    // in the strip of the fighters)
    const opener = this.usedOpener?.dataset.panelId === this.openPanelId && this.usedOpener.isConnected
      ? this.usedOpener
      : this.openerTargets.find((target) => target.dataset.panelId === this.openPanelId)
    this.openPanelId = null
    this.panelTargets.forEach((panel) => panel.removeAttribute("data-open"))
    this.openerTargets.forEach((target) => target.setAttribute("aria-expanded", "false"))
    this.remember(null)
    // Its ring only after the keyboard (Escape, Space, Enter: a click from Enter has no detail), as for the settings;
    // back on the bar with the keyboard, the bar unfolds again with its names
    const closedWithKeyboard = event?.type === "keydown" || event?.detail === 0
    if (closedWithKeyboard) this.releaseToolbar()
    opener?.focus({ focusVisible: closedWithKeyboard })
  }

  // A page opened on #game-room-panel-… shows that panel by :target: it is opened here instead, and the address loses
  // its #, so that another icon never shows a second panel over it
  takeOverTargetedPanel() {
    const targetedPanel = this.panelTargets.find((panel) => `#${panel.id}` === window.location.hash)
    if (!targetedPanel) return null

    history.replaceState(history.state, "", window.location.pathname + window.location.search)
    return targetedPanel.id
  }

  get storageKey() {
    return `game_room_panel:${window.location.pathname}`
  }

  // Storage can be blocked (private window): the panels still open, only the room forgets which one
  rememberedPanelId() {
    try {
      return sessionStorage.getItem(this.storageKey)
    } catch {
      return null
    }
  }

  remember(panelId) {
    try {
      if (panelId) {
        sessionStorage.setItem(this.storageKey, panelId)
      } else {
        sessionStorage.removeItem(this.storageKey)
      }
    } catch {
      // Nothing to do: the room opens with no panel next time
    }
  }
}
