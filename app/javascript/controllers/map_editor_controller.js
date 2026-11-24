import { Controller } from "@hotwired/stimulus"
import SquareGrid, { cellSize } from "map_editor/square_grid"
import BoardView from "map_editor/board_view"
import DrawingHistory from "map_editor/drawing_history"
import MapLayout from "map_editor/map_layout"
import { renderMap } from "map_editor/map_renderer"
import { addMapPatterns } from "map_editor/patterns"
import { createSvgElement, polygonPath, rounded } from "map_editor/svg"
import { allowedMark, refusedMark, voidGround } from "map_editor/palette"
import { floorOf } from "map_floors"
import { edgeOf, doorKey } from "map_edges"

// The map editor (the page of a map in « Mes cartes », laid out like the prototype): the game master picks a tool
// (a floor, a wall or a door, the eraser), then paints the cells or the sides of the board with the pointer. Each
// stroke is saved in the background once the pointer is released (MapTemplates::LayoutsController), one save at a
// time; only a failure is said, on the bar. The board fills its room and shows the whole map at first; the wheel (or
// a pinch of the touchpad, or of two fingers) zooms around the pointer, the space bar held or the middle button (or
// two fingers) moves the map, the buttons of the bar zoom too. Undo and Redo (and their keys) go back through the
// strokes, Clear everything empties the board (undone like a stroke). The board and the tools are rendered hidden and
// shown here: without JavaScript there is nothing to draw with
const toolDrawings = { floor: floorOf, edge: edgeOf }
const zoomStep = 1.25

export default class extends Controller {
  static targets = ["board", "drawing", "pointerMarks", "toolbar", "tool", "swatch", "status", "figures", "zoomLabel",
                     "undoButton", "redoButton", "clearButton"]
  static values = { layout: Object, columns: Number, rows: Number, url: String, saveFailedMessage: String,
                    figureLabels: Object }

  connect() {
    this.grid = new SquareGrid(this.columnsValue, this.rowsValue)
    this.layout = new MapLayout(this.layoutValue)
    this.history = new DrawingHistory()
    // The first floor: the eraser comes first in the page, on the bar
    this.tool = toolOf(this.toolTargets.find((button) => button.dataset.toolKind === "floor"))
    this.view = new BoardView(this.grid, cellSize)
    this.activePointers = new Map()
    this.boardResizeObserver = new ResizeObserver(() => this.resizeView())
    this.boardResizeObserver.observe(this.boardTarget)
    this.drawEverything()
  }

  disconnect() {
    this.boardResizeObserver.disconnect()
  }

  // Also after a refresh by morphing (renaming the map), which puts back the page as the server drew it: hidden, the
  // board empty. What is drawn stays in this controller
  drawEverything() {
    this.boardTarget.style.backgroundColor = voidGround
    this.boardTarget.querySelector("defs")?.remove()
    addMapPatterns(this.boardTarget)
    this.swatchTargets.forEach((swatch) => {
      swatch.replaceChildren()
      toolDrawings[swatch.dataset.toolKind](swatch.dataset.toolKey).drawSwatch(swatch)
    })
    this.pressCurrentTool()
    this.render()
    this.showHistory()
    // An <svg> has no hidden property (only HTML elements do): the attribute itself is taken away
    this.boardTarget.removeAttribute("hidden")
    this.toolbarTarget.hidden = false
    this.resizeView()
  }

  resizeView() {
    if (!this.boardTarget.clientWidth || !this.boardTarget.clientHeight) return

    this.view.resize(this.boardTarget.clientWidth, this.boardTarget.clientHeight)
    this.showView()
  }

  showView() {
    this.boardTarget.setAttribute("viewBox", this.view.viewBox())
    this.zoomLabelTarget.textContent = `${this.view.zoomPercent()} %`
  }

  zoomIn() {
    this.view.zoomAround([this.view.centerX, this.view.centerY], zoomStep)
    this.showView()
  }

  zoomOut() {
    this.view.zoomAround([this.view.centerX, this.view.centerY], 1 / zoomStep)
    this.showView()
  }

  showWholeMap() {
    this.view.fitWholeMap()
    this.showView()
  }

  // A pinch of a touchpad comes as a wheel with ctrlKey, in smaller steps than a mouse wheel
  zoomWithWheel(event) {
    event.preventDefault()
    const speed = event.ctrlKey ? 0.01 : 0.0015
    this.view.zoomAround(this.boardPoint(event), Math.exp(-event.deltaY * speed))
    this.showView()
  }

  // The space bar held over the board moves the map instead of drawing, as in drawing apps. Not while typing, nor
  // while the pointer is elsewhere: space still presses a focused button
  holdSpace(event) {
    if (!this.isPointerOverBoard || isTyping(event)) return

    event.preventDefault()
    this.isSpaceHeld = true
    this.boardTarget.style.cursor = "grab"
  }

  releaseSpace(event) {
    if (!this.isSpaceHeld) return

    event.preventDefault()
    this.isSpaceHeld = false
    this.boardTarget.style.cursor = ""
  }

  enterBoard() {
    this.isPointerOverBoard = true
  }

  chooseTool(event) {
    this.tool = toolOf(event.currentTarget)
    this.pressCurrentTool()
  }

  pressCurrentTool() {
    this.toolTargets.forEach((button) => {
      const isCurrent = button.dataset.toolKind === this.tool.kind && button.dataset.toolKey === this.tool.key
      button.setAttribute("aria-pressed", isCurrent)
    })
  }

  // One finger or the main button draws; a second finger turns the stroke into a pinch; the middle button, or the
  // space bar held, moves the map
  startStroke(event) {
    this.boardTarget.setPointerCapture(event.pointerId)
    this.activePointers.set(event.pointerId, [event.clientX, event.clientY])
    if (this.activePointers.size === 2) return this.startPinch()
    if (event.button === 1 || this.isSpaceHeld) {
      // The middle button would otherwise start the scrolling of the browser
      event.preventDefault()
      this.panningFrom = [event.clientX, event.clientY]
      return
    }
    if (event.button !== 0) return

    this.stroke = { changed: false, removing: null, before: this.layout.snapshot() }
    this.applyTool(event)
  }

  continueStroke(event) {
    if (this.activePointers.has(event.pointerId)) this.activePointers.set(event.pointerId, [event.clientX, event.clientY])
    if (this.pinch) return this.continuePinch()
    if (this.panningFrom) return this.continuePanning(event)
    if (this.stroke) this.applyTool(event)
    this.markPointer(event)
  }

  endStroke(event) {
    this.activePointers.delete(event.pointerId)
    if (this.activePointers.size < 2) this.pinch = null
    this.panningFrom = null
    this.finishStroke()
  }

  finishStroke() {
    if (this.stroke?.changed) this.keepChange(this.stroke.before)
    this.stroke = null
  }

  // A change made: it can be undone, and it is saved
  keepChange(before) {
    this.history.record(before)
    this.showHistory()
    this.save()
  }

  undo() {
    this.goBackTo(this.history.undo(this.layout.snapshot()))
  }

  redo() {
    this.goBackTo(this.history.redo(this.layout.snapshot()))
  }

  goBackTo(snapshot) {
    if (!snapshot) return

    this.layout.restore(snapshot)
    this.render()
    this.showHistory()
    this.save()
  }

  clearEverything() {
    if (this.layout.isEmpty()) return

    const before = this.layout.snapshot()
    this.layout.clear()
    this.render()
    this.keepChange(before)
  }

  // Ctrl or Cmd + Z undoes, with Shift (or Ctrl + Y) redoes. Not while typing: a field undoes its own text
  undoWithKeys(event) {
    if (!(event.ctrlKey || event.metaKey) || isTyping(event)) return

    const key = event.key.toLowerCase()
    if (key !== "z" && key !== "y") return

    event.preventDefault()
    if (key === "y" || event.shiftKey) this.redo()
    else this.undo()
  }

  showHistory() {
    this.undoButtonTarget.disabled = !this.history.canUndo()
    this.redoButtonTarget.disabled = !this.history.canRedo()
    this.clearButtonTarget.disabled = this.layout.isEmpty()
  }

  hidePointer() {
    this.isPointerOverBoard = false
    this.pointerMarksTarget.replaceChildren()
  }

  continuePanning(event) {
    this.view.moveByPixels(event.clientX - this.panningFrom[0], event.clientY - this.panningFrom[1])
    this.panningFrom = [event.clientX, event.clientY]
    this.showView()
  }

  // What the first finger painted before the second one came stays (and is saved)
  startPinch() {
    this.finishStroke()
    this.hidePointer()
    this.pinch = this.pinchShape()
  }

  continuePinch() {
    const shape = this.pinchShape()
    this.view.zoomAround(this.boardPoint({ clientX: shape.middle[0], clientY: shape.middle[1] }),
                         shape.distance / this.pinch.distance)
    this.view.moveByPixels(shape.middle[0] - this.pinch.middle[0], shape.middle[1] - this.pinch.middle[1])
    this.pinch = shape
    this.showView()
  }

  pinchShape() {
    const [first, second] = [...this.activePointers.values()]
    return { distance: Math.hypot(second[0] - first[0], second[1] - first[1]) || 1,
             middle: [(first[0] + second[0]) / 2, (first[1] + second[1]) / 2] }
  }

  render() {
    renderMap(this.drawingTarget, { grid: this.grid, floors: this.layout.floors, edges: this.layout.edges })
    this.showFigures()
  }

  // « 120 cases · 14 murs · 3 portes », in the plural rules of the language of the page
  showFigures() {
    const doorCount = [...this.layout.edges.values()].filter((edgeKey) => edgeKey === doorKey).length
    const counts = { cells: this.layout.floors.size, walls: this.layout.edges.size - doorCount, doors: doorCount }
    const pluralRules = new Intl.PluralRules(document.documentElement.lang || "en")
    this.figuresTarget.textContent = Object.entries(counts).map(([figure, count]) => {
      const labels = this.figureLabelsValue[figure]
      return (labels[pluralRules.select(count)] ?? labels.other).replace("%{count}", count)
    }).join(" · ")
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

  // Not on the edge of the grid: the cell across it is outside, and the server would refuse the drawing
  mayHoldEdge(side) {
    return this.grid.inside(side.neighbourColumn, side.neighbourRow) && this.layout.mayHoldEdge(side, this.tool.key)
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

function isTyping(event) {
  return Boolean(event.target.closest?.("input, textarea, select, [contenteditable]"))
}

function toolOf(button) {
  return { kind: button.dataset.toolKind, key: button.dataset.toolKey }
}
