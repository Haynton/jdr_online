// Runs in the <head>, before the page is painted, like theme_preload.js: setting the class from a Stimulus
// controller would first show the folded side navigation, then make it jump open.
// Must stay in sync with controllers/side_nav_controller.js: same storage key, same value.
(() => {
  const sideNavStorageKey = "side_nav"
  const expandedValue = "expanded"

  // Storage can be blocked (private browsing, strict privacy settings): the navigation then stays folded
  const readSavedState = () => {
    try {
      return localStorage.getItem(sideNavStorageKey)
    } catch {
      return null
    }
  }

  document.documentElement.classList.toggle("nav-expanded", readSavedState() === expandedValue)
})()
