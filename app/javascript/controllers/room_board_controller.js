import { Controller } from "@hotwired/stimulus"

// The board of the game room, first version (the real board comes with its own branch; nothing here is saved or
// shared): « Placer » on a map of the panel « Cartes » shows it on the whole board, drawn like its preview, with its
// tokens, and « Retirer » takes it off; « Placer » on an NPC or an enemy of the panel « PNJ et ennemis » then takes it as a tool, like a token in the map
// editor: each click on the map puts its token on the cell under the pointer (one per cell), until Escape, a right
// click or another tool. Without a map on the board, the buttons of the creatures say so and do nothing. Their
// buttons are rendered hidden and shown here: without JavaScript there is no board
const CELL_SIZE = 24

export default class extends Controller {
  static targets = ["map", "placeholder", "mapPlacer", "creaturePlacer", "hint", "hintName"]
  static values = { hint: String }

  connect() {
    this.mapPlacerTargets.forEach((button) => { button.hidden = false })
  }

  creaturePlacerTargetConnected(button) {
    button.hidden = false
    this.showCreaturePlacer(button)
  }

  // « Placer » shows the map on the board, instead of the one there; on the map already there, « Retirer » takes it off
  placeMap(event) {
    const mapId = String(event.params.id)
    this.showMap(this.mapId === mapId ? null : mapId)
  }

  showMap(mapId) {
    this.mapId = mapId
    if (!mapId) this.dropCreature()
    // An <svg> has no hidden property: the attribute itself (rule noted in CLAUDE.md)
    this.mapTargets.forEach((map) => map.toggleAttribute("hidden", map.dataset.mapId !== mapId))
    this.placeholderTarget.hidden = Boolean(mapId)
    this.mapPlacerTargets.forEach((button) => {
      const onBoard = button.dataset.roomBoardIdParam === mapId
      button.setAttribute("aria-pressed", String(onBoard))
      button.setAttribute("aria-label", onBoard ? button.dataset.removeLabel : button.dataset.placeLabel)
    })
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
  }

  showCreaturePlacer(button) {
    button.setAttribute("aria-disabled", String(!this.mapId))
    button.title = this.mapId ? button.dataset.placeLabel : button.dataset.needsMapLabel
  }

  // « Placer » on a creature: it becomes the tool of the board
  takeCreature(event) {
    if (!this.mapId) return

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

  // Escape lets the tool go (a window open above keeps its own Escape)
  dropCreatureWithKeys() {
    if (this.creature && !document.querySelector("dialog[open]")) this.dropCreature()
  }

  // A right click on the map lets the tool go, as in the map editor
  dropCreatureWithRightClick(event) {
    if (!this.creature) return

    event.preventDefault()
    this.dropCreature()
  }

  // The cell under the pointer, from the coordinates of the drawing (24 units per cell)
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
