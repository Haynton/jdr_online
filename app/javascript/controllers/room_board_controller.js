import { Controller } from "@hotwired/stimulus"

const CELL_SIZE = 24

export default class extends Controller {
  static targets = ["map", "creaturePlacer", "hint", "hintName"]
  static values = { hint: String }

  mapTargetConnected() {
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
  }

  mapTargetDisconnected() {
    this.dropCreature()
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
  }

  creaturePlacerTargetConnected(button) {
    button.hidden = false
    this.showCreaturePlacer(button)
  }

  showCreaturePlacer(button) {
    button.setAttribute("aria-disabled", String(!this.hasMapTarget))
    button.title = this.hasMapTarget ? button.dataset.placeLabel : button.dataset.needsMapLabel
  }

  takeCreature(event) {
    if (!this.hasMapTarget) return

    this.creature = { id: event.params.id, name: event.params.name, kind: event.params.kind }
    this.hintNameTarget.textContent = this.hintValue.replace("__NAME__", this.creature.name)
    this.hintTarget.hidden = false
    this.element.setAttribute("data-placing", "")
  }

  dropCreature() {
    this.creature = null
    if (this.hasHintTarget) this.hintTarget.hidden = true
    this.element.removeAttribute("data-placing")
  }

  dropCreatureWithKeys() {
    if (this.creature && !document.querySelector("dialog[open]")) this.dropCreature()
  }

  dropCreatureWithRightClick(event) {
    if (!this.creature) return

    event.preventDefault()
    this.dropCreature()
  }

  placeAtPointer(event) {
    if (!this.creature) return

    const map = event.currentTarget
    const point = new DOMPoint(event.clientX, event.clientY).matrixTransform(map.getScreenCTM().inverse())
    const column = Math.floor(point.x / CELL_SIZE)
    const row = Math.floor(point.y / CELL_SIZE)
    const preview = this.application.getControllerForElementAndIdentifier(map, "map-preview")
    if (column < 0 || row < 0 || column >= preview.columnsValue || row >= preview.rowsValue) return

    preview.placeToken(this.creature, column, row)
  }
}
