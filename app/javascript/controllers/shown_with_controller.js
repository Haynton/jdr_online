import { Controller } from "@hotwired/stimulus"

// The fields shown only for some values of a list (shown_with: the damage of an item, for a weapon only), as
// FieldShownWith on the server: while the list changes, each field (a fieldset with data-field, the key of the list,
// and data-values, the values it shows for) is shown or hidden, and disabled while hidden so that it is not sent. A cell
// or a section with nothing left to show is hidden too
export default class extends Controller {
  static targets = ["field", "cell", "section"]

  refresh() {
    this.fieldTargets.forEach((field) => {
      const shown = JSON.parse(field.dataset.values).includes(this.valueOf(field.dataset.field))
      field.hidden = !shown
      field.disabled = !shown
    })
    this.cellTargets.forEach((cell) => { cell.hidden = !this.showsSomething(cell) })
    this.sectionTargets.forEach((section) => {
      section.hidden = !this.cellTargets.some((cell) => section.contains(cell) && !cell.hidden)
    })
  }

  // The value of the list, whatever the scope of its name (catalog_entry[properties][category])
  valueOf(key) {
    const list = this.element.querySelector(`select[name$="[${key}]"]`)
    return list ? list.value : ""
  }

  // A cell shows something while one of its children is not a hidden field
  showsSomething(cell) {
    return [...cell.children].some((child) => !(this.fieldTargets.includes(child) && child.hidden))
  }
}
