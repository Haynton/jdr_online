import { Controller } from "@hotwired/stimulus"

// Must stay in sync with side_nav_preload.js: same storage key, same value
const sideNavStorageKey = "side_nav"
const expandedValue = "expanded"
const expandedClass = "nav-expanded"

// Folds and unfolds the side navigation of a signed in user (from 768 px): icons only, or icons and labels.
// Folded is the default; the choice is remembered in this browser. The button is rendered hidden:
// without JavaScript it would do nothing. Its visible text follows the .nav-expanded class (CSS),
// only its tooltip needs this controller
export default class extends Controller {
  static targets = ["toggleButton"]
  static values = { expandLabel: String, collapseLabel: String }

  connect() {
    this.toggleButtonTarget.hidden = false
    this.showState()
  }

  toggle() {
    const isExpanded = document.documentElement.classList.toggle(expandedClass)
    this.saveState(isExpanded)
    this.showState()
  }

  showState() {
    const isExpanded = document.documentElement.classList.contains(expandedClass)
    this.toggleButtonTarget.title = isExpanded ? this.collapseLabelValue : this.expandLabelValue
  }

  // Storage can be blocked: the navigation still unfolds, only the choice is not remembered
  saveState(isExpanded) {
    try {
      if (isExpanded) {
        localStorage.setItem(sideNavStorageKey, expandedValue)
      } else {
        localStorage.removeItem(sideNavStorageKey)
      }
    } catch {
      // Nothing to do: the next page starts folded
    }
  }
}
