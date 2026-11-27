import { Controller } from "@hotwired/stimulus"

// The book of spells of a feat (game_tables/character_steps/_feat_spell_picks): the spell under
// the pointer, touched, or reached with the keyboard shows its details there, copied from its template (decision: no
// (i) to open a window). Until then, the page shows what the server put in it (the first spell picked)
export default class extends Controller {
  static targets = ["panel", "details"]

  show({ currentTarget }) {
    const item = currentTarget.closest("[data-spell-preview-item]")
    if (item) this.showItem(item)
  }

  showItem(item) {
    const template = item.querySelector("template[data-spell-preview-target='details']")
    if (!template || this.shown === template) return

    this.shown = template
    this.panelTarget.replaceChildren(template.content.cloneNode(true))
  }
}
