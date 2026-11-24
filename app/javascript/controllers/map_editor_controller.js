import { Controller } from "@hotwired/stimulus"
import SquareGrid from "map_editor/square_grid"
import MapLayout from "map_editor/map_layout"
import { renderMap } from "map_editor/map_renderer"
import { addMapPatterns } from "map_editor/patterns"
import { createSvgElement, polygonPath, rounded } from "map_editor/svg"
import { allowedMark, refusedMark } from "map_editor/palette"
import { floorOf } from "map_floors"
import { edgeOf } from "map_edges"

// The map editor (the page of a map in « Mes cartes »): the game master picks a tool (a floor, a wall or a door, the
// eraser), then paints the cells or the sides of the board with the pointer. Each stroke is saved in the background
// once the pointer is released (MapTemplates::LayoutsController), one save at a time; only a failure is said, under
// the board. The editor is rendered hidden and shown here: without JavaScript there is nothing to draw with
const toolDrawings = { floor: floorOf, edge: edgeOf }

export default class extends Controller {
  static targets = ["editor", "board", "drawing", "pointerMarks", "tool", "swatch", "status"]
  static values = { layout: Object, columns: Number, rows: Number, url: String, saveFailedMessage: String }

  connect() {
    this.grid = new SquareGrid(this.columnsValue, this.rowsValue)
    this.layout = new MapLayout(this.layoutValue)
    this.boardTarget.setAttribute("viewBox", `0 0 ${this.grid.width} ${this.grid.height}`)
    // Back on the page from the cache of Turbo, the textures and the swatches are there already
    this.boardTarget.querySelector("defs")?.remove()
    addMapPatterns(this.boardTarget)
    this.swatchTargets.forEach((swatch) => {
      swatch.replaceChildren()
      toolDrawings[swatch.dataset.toolKind](swatch.dataset.toolKey).drawSwatch(swatch)
    })
    this.selectTool(this.toolTargets[0])
    this.render()
    this.editorTarget.hidden = false
  }

  chooseTool(event) {
    this.selectTool(event.currentTarget)
  }

  startStroke(event) {
    if (event.button !== 0) return

    this.boardTarget.setPointerCapture(event.pointerId)
    this.stroke = { changed: false, removing: null }
    this.applyTool(event)
  }

  continueStroke(event) {
    if (this.stroke) this.applyTool(event)
    this.markPointer(event)
  }

  endStroke() {
    if (this.stroke?.changed) this.save()
    this.stroke = null
  }

  hidePointer() {
    this.pointerMarksTarget.replaceChildren()
  }

  selectTool(button) {
    this.tool = { kind: button.dataset.toolKind, key: button.dataset.toolKey }
    this.toolTargets.forEach((toolButton) => toolButton.setAttribute("aria-pressed", toolButton === button))
  }

  render() {
    renderMap(this.drawingTarget, { grid: this.grid, floors: this.layout.floors, edges: this.layout.edges })
  }

  applyTool(event) {
    const side = this.grid.nearestSide(this.boardPoint(event))
    if (!this.grid.inside(side.column, side.row)) return
    if (!this.changeLayout(side)) return

    this.stroke.changed = true
    this.render()
  }

  // A floor paints its cell, the eraser takes a wall or a floor. A wall or a door: the first side of the stroke says
  // whether the stroke puts that wall, or takes it away from the sides that hold it already
  changeLayout(side) {
    if (this.tool.kind === "floor") return this.layout.paintFloor(side.column, side.row, this.tool.key)
    if (this.tool.kind === "eraser") return this.layout.erase(side)
    if (!this.mayHoldEdge(side)) return false

    this.stroke.removing ??= this.layout.hasEdge(side, this.tool.key)
    return this.stroke.removing ? this.layout.removeEdge(side) : this.layout.putEdge(side, this.tool.key)
  }

  // Where the tool would act: the cell, or the side for a wall, in red where a wall cannot stand
  markPointer(event) {
    this.hidePointer()
    const side = this.grid.nearestSide(this.boardPoint(event))
    if (!this.grid.inside(side.column, side.row)) return

    if (this.tool.kind === "edge") return this.markSide(side)
    createSvgElement("path", { d: polygonPath(this.grid.corners(side.column, side.row)), fill: allowedMark,
                               "fill-opacity": 0.12, stroke: allowedMark, "stroke-width": 1.5,
                               "stroke-dasharray": "3 3" }, this.pointerMarksTarget)
  }

  markSide(side) {
    const { start, end } = this.grid.side(side.column, side.row, side.sideIndex)
    const color = this.mayHoldEdge(side) ? allowedMark : refusedMark
    createSvgElement("line", { x1: rounded(start[0]), y1: rounded(start[1]), x2: rounded(end[0]), y2: rounded(end[1]),
                               stroke: color, "stroke-width": 4, "stroke-opacity": 0.6, "stroke-linecap": "round" },
                     this.pointerMarksTarget)
  }

  // Not on the edge of the grid: the cell across it is outside, and the server would refuse the drawing
  mayHoldEdge(side) {
    return this.grid.inside(side.neighbourColumn, side.neighbourRow) && this.layout.mayHoldEdge(side, this.tool.key)
  }

  boardPoint(event) {
    const point = this.boardTarget.createSVGPoint()
    point.x = event.clientX
    point.y = event.clientY
    const { x, y } = point.matrixTransform(this.boardTarget.getScreenCTM().inverse())
    return [x, y]
  }

  // One save at a time, so that an older drawing never arrives last: a stroke made meanwhile is sent once it is back
  async save() {
    if (this.isSaving) {
      this.hasUnsavedStroke = true
      return
    }
    this.isSaving = true
    this.hasUnsavedStroke = false
    const isSaved = await this.request().then((response) => response.ok, () => false)
    this.isSaving = false
    this.statusTarget.textContent = isSaved ? "" : this.saveFailedMessageValue
    if (this.hasUnsavedStroke) this.save()
  }

  // keepalive: the last stroke is still saved when the page is left right after it
  request() {
    const body = new FormData()
    body.append("layout", JSON.stringify(this.layout.toJSON()))
    return fetch(this.urlValue, {
      method: "PATCH",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content, Accept: "application/json" }
    })
  }
}
