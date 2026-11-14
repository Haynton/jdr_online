import { Controller } from "@hotwired/stimulus"

// Must stay in sync with theme_preload.js: same storage key, same values
const themeStorageKey = "theme"
const systemDarkQuery = "(prefers-color-scheme: dark)"

export default class extends Controller {
  static targets = ["choiceButton"]

  connect() {
    this.systemDarkMedia = window.matchMedia(systemDarkQuery)
    this.followSystemChange = () => this.applyTheme()
    this.systemDarkMedia.addEventListener("change", this.followSystemChange)
    this.applyTheme()
  }

  disconnect() {
    this.systemDarkMedia.removeEventListener("change", this.followSystemChange)
  }

  choose({ params: { choice } }) {
    this.saveChoice(choice)
    this.applyTheme()
  }

  applyTheme() {
    const savedChoice = this.readSavedChoice()
    document.documentElement.classList.toggle("dark", this.isDark(savedChoice))
    this.choiceButtonTargets.forEach((choiceButton) => {
      const isSelected = choiceButton.dataset.themeChoiceParam === savedChoice
      choiceButton.setAttribute("aria-pressed", String(isSelected))
    })
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
