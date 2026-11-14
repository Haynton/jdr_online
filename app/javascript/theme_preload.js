// Runs in the <head>, before the page is painted. Stimulus controllers load later (as deferred
// modules): setting the class from there would first show the light theme, then flash to dark.
// Must stay in sync with controllers/theme_controller.js: same storage key, same values.
(() => {
  const themeStorageKey = "theme"

  // Storage can be blocked (private browsing, strict privacy settings): fall back to the system theme
  const readSavedTheme = () => {
    try {
      return localStorage.getItem(themeStorageKey)
    } catch {
      return null
    }
  }

  const savedTheme = readSavedTheme()
  const followsSystem = savedTheme !== "light" && savedTheme !== "dark"
  const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
  const useDarkTheme = followsSystem ? systemPrefersDark : savedTheme === "dark"

  document.documentElement.classList.toggle("dark", useDarkTheme)
})()
