import { Controller } from "@hotwired/stimulus"

// Must stay in sync with theme_preload.js: same storage key, same values
const themeStorageKey = "theme"
const systemDarkQuery = "(prefers-color-scheme: dark)"
// Several theme controls can share a page (navbar switch, display settings): each one tells the others
const themeChangedEvent = "theme:changed"

export default class extends Controller {
  // choiceButton: the three choices (light, dark, system) of the visitor pages and of the display settings
  // switch: the light or dark switch of the navbar
  static targets = ["choiceButton", "switch"]

  connect() {
    this.systemDarkMedia = window.matchMedia(systemDarkQuery)
    this.followThemeChange = () => this.applyTheme()
    this.systemDarkMedia.addEventListener("change", this.followThemeChange)
    window.addEventListener(themeChangedEvent, this.followThemeChange)
    this.applyTheme()
  }

  disconnect() {
    this.systemDarkMedia.removeEventListener("change", this.followThemeChange)
    window.removeEventListener(themeChangedEvent, this.followThemeChange)
  }

  choose({ params: { choice } }) {
    this.saveChoice(choice)
    this.announceThemeChange()
  }

  // The switch leaves the system mode: it saves the theme opposite to the one shown
  toggle() {
    const isDark = this.isDark(this.readSavedChoice())
    this.saveChoice(isDark ? "light" : "dark")
    this.announceThemeChange()
  }

  // Every theme control of the page, this one included, applies the new choice
  announceThemeChange() {
    window.dispatchEvent(new CustomEvent(themeChangedEvent))
  }

  applyTheme() {
    const savedChoice = this.readSavedChoice()
    const isDark = this.isDark(savedChoice)
    document.documentElement.classList.toggle("dark", isDark)
    this.choiceButtonTargets.forEach((choiceButton) => {
      const isSelected = choiceButton.dataset.themeChoiceParam === savedChoice
      choiceButton.setAttribute("aria-pressed", String(isSelected))
    })
    this.switchTargets.forEach((themeSwitch) => themeSwitch.setAttribute("aria-checked", String(isDark)))
  }

  isDark(choice) {
    if (choice === "system") return this.systemDarkMedia.matches
    return choice === "dark"
  }

  // "system" is stored as no value at all, exactly what theme_preload.js reads as "follow the device"
  saveChoice(choice) {
    try {
      if (choice === "system") {
        localStorage.removeItem(themeStorageKey)
      } else {
        localStorage.setItem(themeStorageKey, choice)
      }
    } catch {
      // Storage blocked: the choice still applies to this page, it just is not remembered
    }
  }

  readSavedChoice() {
    try {
      const storedChoice = localStorage.getItem(themeStorageKey)
      return ["light", "dark"].includes(storedChoice) ? storedChoice : "system"
    } catch {
      return "system"
    }
  }
}
