import { Controller } from "@hotwired/stimulus"

// The search of the step "Spells and items" of a table: hides the entries whose name does not contain what is typed,
// without accents or capitals ("Détection" and "detection" find each other, as TableCatalogHelper#catalog_search_name
// on the server), then the groups left empty, and says so when nothing is left. The search is rendered hidden and
// shown here: without JavaScript, every entry stays shown. The page is refreshed by morphing once an entry or a switch
// is saved: the search, hidden again by the page from the server, is shown again and applied again (turbo:morph)
export default class extends Controller {
  static targets = ["tools", "search", "entry", "group", "noMatch"]

  connect() {
    this.showTools()
  }

  showTools() {
    if (!this.hasToolsTarget) return

    this.toolsTarget.hidden = false
    if (this.searchTarget.value) this.filter()
  }

  filter() {
    const query = searchable(this.searchTarget.value)
    this.entryTargets.forEach((entry) => { entry.hidden = !entry.dataset.searchName.includes(query) })
    this.groupTargets.forEach((group) => {
      group.hidden = !group.querySelector("[data-catalog-search-target='entry']:not([hidden])")
    })
    this.noMatchTarget.hidden = this.groupTargets.some((group) => !group.hidden)
  }
}

function searchable(text) {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim()
}
