import { Controller } from "@hotwired/stimulus"

// Tabs: a row of tab buttons, one panel shown at a time (the pattern of tabs of the WAI-ARIA guide: arrows and
// Home / End move between the tabs, the chosen tab alone is in the tab order). The tab list is rendered hidden and
// shown here: without JavaScript, every panel shows one under the other, under its own heading. A refresh by morphing
// puts the page back as the server drew it: the choice is shown again. selectedIndex: the tab shown first (a form
// refused in another tab than the first one shows its errors)
export default class extends Controller {
  static targets = ["list", "tab", "panel"]
  static values = { selectedIndex: Number }

  connect() {
    this.selectedIndex = this.selectedIndexValue
    this.show()
  }

  // After a refresh by morphing (turbo:morph), which puts back the page as the server drew it
  refresh() {
    this.show()
  }

  choose(event) {
    this.selectedIndex = this.tabTargets.indexOf(event.currentTarget)
    this.show()
  }

  moveWithKeys(event) {
    const lastIndex = this.tabTargets.length - 1
    const nextIndexByKey = { ArrowRight: this.selectedIndex + 1, ArrowLeft: this.selectedIndex - 1, Home: 0,
                             End: lastIndex }
    if (!(event.key in nextIndexByKey)) return

    event.preventDefault()
    this.selectedIndex = (nextIndexByKey[event.key] + lastIndex + 1) % (lastIndex + 1)
    this.show()
    this.tabTargets[this.selectedIndex].focus()
  }

  show() {
    this.listTarget.hidden = false
    this.tabTargets.forEach((tab, index) => {
      const isSelected = index === this.selectedIndex
      tab.setAttribute("aria-selected", isSelected)
      tab.tabIndex = isSelected ? 0 : -1
    })
    this.panelTargets.forEach((panel, index) => { panel.hidden = index !== this.selectedIndex })
  }
}
