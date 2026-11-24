import { Controller } from "@hotwired/stimulus"
import SquareGrid from "map_editor/square_grid"
import BoardView from "map_editor/board_view"
import DrawingHistory from "map_editor/drawing_history"
import MapLayout from "map_editor/map_layout"
import { renderMap, objectCenter, drawPlacedObject } from "map_editor/map_renderer"
import { renderPicture } from "map_editor/picture_renderer"
import { renderBlockedCells } from "map_editor/blocked_renderer"
import { drawFloorSample } from "map_editor/floor_sample"
import { defaultPicture, withCellsWide, centered, sliders } from "map_editor/picture_settings"
import { addMapPatterns } from "map_editor/patterns"
import { createSvgElement, polygonPath, rounded } from "map_editor/svg"
import { allowedMark, refusedMark, voidGround } from "map_editor/palette"
import { edgeOf, doorKey } from "map_edges"
import { objectOf, drawObjectSwatch } from "map_objects"
import { confirmWithDialog } from "confirm_dialog"

// The map editor (the page of a map in « Mes cartes », laid out like the prototype): the game master picks a tool
// (a floor, a wall or a door, the eraser), then paints the cells or the sides of the board with the pointer. Each
// stroke is saved in the background once the pointer is released (MapTemplates::LayoutsController), one save at a
// time; only a failure is said, on the bar. The board fills its room and shows the whole map at first; the wheel (or
// a pinch of the touchpad, or of two fingers) zooms around the pointer, the space bar held or the middle button (or
// two fingers) moves the map, the buttons of the bar zoom too. Undo and Redo (and their keys) go back through the
// strokes, Clear everything empties the board (undone like a stroke). An object is put with a click, in the direction
// chosen by Turn (R); a click on an object put turns it; Take object away, a right click or Delete takes it (or a wall)
// away. The number of columns of the bar resizes the grid, the rows following to keep its proportions (Anthony's
// request): cells added or taken away on the right and at the bottom, asked first when something drawn would go,
// undone like a stroke. The bar says when the drawing was saved. On a map of a table, the brush « Zones bloquantes »
// paints the cells no token stands on, drawn or on a picture (the first cell of the stroke says whether it paints or
// takes the paint away). The board and the tools are rendered hidden and shown here: without JavaScript there is
// nothing to draw with
const toolSwatches = {
  floor: (swatch, key) => drawFloorSample(swatch, key),
  edge: (swatch, key) => edgeOf(key).drawSwatch(swatch),
  object: (swatch, key) => drawObjectSwatch(swatch, key)
}
// How close to a side a right click must be to take its wall away
const deletingReach = 6
// The tools that only take away: clicked again, they give back the tool used before them (Anthony's request)
// The tools of the bar left by clicking them again: the tool used before comes back
const toolsLeftByClickingAgain = ["eraser", "remover", "hand", "blocker"]
// The bounds of a grid, the same as MapTemplate::GRID_SIZES
const smallestGridSize = 10
const largestGridSize = 60
const zoomStep = 1.25
const deletingKeys = ["Delete", "Backspace"]
// The room kept between the floating pieces and the map, in pixels
const floatingRoom = 8
// A line of a wheel turned by lines, in pixels
const pixelsPerWheelLine = 40

export default class extends Controller {
  static targets = ["board", "drawing", "pointerMarks", "toolbar", "tool", "swatch", "status", "figures",
                     "undoButton", "redoButton", "clearButton", "rotationLabel", "columnsInput", "rowsCount",
                     "saveState", "zoomButtons", "presetPreview", "makingChoice", "drawingPanel", "picturePanel",
                     "drawingTools", "pictureWidth", "pictureSlider", "gridSize"]
  static values = { layout: Object, columns: Number, rows: Number, url: String, saveFailedMessage: String,
                    figureLabels: Object, rotationLabel: String, savingLabel: String, savedLabel: String,
                    shrinkQuestion: String, clearQuestion: String, replaceQuestion: String, pictureUrl: String }

  connect() {
    this.grid = new SquareGrid(this.columnsValue, this.rowsValue)
    this.layout = new MapLayout(this.layoutValue, this.grid)
    this.placementRotation = 0
    // The proportions of the grid as it was opened: a resize keeps them, without drifting from rounding to rounding
    this.gridRatio = this.rowsValue / this.columnsValue
    this.history = new DrawingHistory()
    // The first floor: the eraser comes first in the page, on the bar
    this.tool = this.firstFloorTool()
    this.view = new BoardView(this.grid)
    this.activePointers = new Map()
    this.boardResizeObserver = new ResizeObserver(() => this.resizeView())
    this.boardResizeObserver.observe(this.boardTarget)
    this.drawEverything()
  }

  // The proportions of the picture of the map, known once it is loaded: it is drawn then. Also when a new picture
  // comes back with the page refreshed by morphing (sent from the tab Image), which does not connect the editor again
  pictureUrlValueChanged() {
    this.pictureRatio = null
    if (!this.pictureUrlValue) return this.layout && this.render()

    const picture = new Image()
    picture.addEventListener("load", () => {
      this.pictureRatio = picture.naturalHeight / picture.naturalWidth
      if (this.layout) this.render()
    })
    picture.src = this.pictureUrlValue
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
      toolSwatches[swatch.dataset.toolKind](swatch, swatch.dataset.toolKey)
    })
    this.drawPresetPreviews()
    this.showRotation()
    this.showSize()
    this.saveStateTarget.textContent = this.lastSaveState ?? ""
    this.pressCurrentTool()
    this.render()
    this.showHistory()
    // An <svg> has no hidden property (only HTML elements do): the attribute itself is taken away
    this.boardTarget.removeAttribute("hidden")
    this.toolbarTarget.hidden = false
    this.zoomButtonsTarget.hidden = false
    this.gridSizeTarget.hidden = false
    this.resizeView()
  }

  resizeView() {
    if (!this.boardTarget.clientWidth || !this.boardTarget.clientHeight) return

    this.view.resize(this.boardTarget.clientWidth, this.boardTarget.clientHeight, this.floatingInsets())
    this.showView()
  }

  // How far the floating pieces reach into the board, side by side: the size of the grid at the top, the help and the
  // zoom on the right, what was saved at the bottom. A little room beyond them, so that a cell is not drawn against
  // their edge
  floatingInsets() {
    const board = this.boardTarget.getBoundingClientRect()
    const reach = (element, side) => {
      if (!element || element.offsetParent === null) return 0

      const piece = element.getBoundingClientRect()
      const distance = { top: piece.bottom - board.top, right: board.right - piece.left,
                         bottom: board.bottom - piece.top }[side]
      return Math.max(0, distance + floatingRoom)
    }
    return { top: reach(this.gridSizeTarget, "top"), right: reach(this.zoomButtonsTarget.parentElement, "right"),
             bottom: reach(this.figuresTarget.parentElement, "bottom"), left: 0 }
  }

  showView() {
    this.boardTarget.setAttribute("viewBox", this.view.viewBox())
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

  // Two fingers sliding on a touchpad move the map (Anthony's request, like Figma: holding space was a chore); a pinch
  // of a touchpad (a wheel with ctrlKey, in small steps) and the wheel of a mouse zoom
  zoomOrMoveWithWheel(event) {
    event.preventDefault()
    if (!event.ctrlKey && isTouchpadSlide(event)) {
      this.view.moveByPixels(-event.deltaX, -event.deltaY)
    } else {
      const speed = event.ctrlKey ? 0.01 : 0.0015
      this.view.zoomAround(this.boardPoint(event), Math.exp(-wheelPixels(event) * speed))
    }
    this.showView()
  }

  // Safari sends the pinch of a touchpad as gestures, not as a wheel: without them, it zoomed the whole page instead
  // of the map. scale is counted from the start of the gesture
  startGesture(event) {
    event.preventDefault()
    this.gestureScale = 1
  }

  zoomWithGesture(event) {
    event.preventDefault()
    this.view.zoomAround(this.boardPoint(event), event.scale / this.gestureScale)
    this.gestureScale = event.scale
    this.showView()
  }

  // The space bar held over the board moves the map instead of drawing, as in drawing apps. Not while typing, nor
  // while the pointer is elsewhere: space still presses a focused button
  holdSpace(event) {
    if (!this.isPointerOverBoard || isTyping(event)) return

    event.preventDefault()
    this.isSpaceHeld = true
    this.showBoardCursor()
  }

  releaseSpace(event) {
    if (!this.isSpaceHeld) return

    event.preventDefault()
    this.isSpaceHeld = false
    this.showBoardCursor()
  }

  enterBoard() {
    this.isPointerOverBoard = true
  }

  // The eraser or Take object away, clicked again while in use, gives back the tool used before it (the first floor
  // at first): the pointer goes back to drawing
  chooseTool(event) {
    const chosenTool = toolOf(event.currentTarget)
    if (isSameTool(chosenTool, this.tool) && toolsLeftByClickingAgain.includes(chosenTool.kind)) {
      this.tool = this.toolBeforeTakingAway ?? this.firstFloorTool()
    } else {
      if (!toolsLeftByClickingAgain.includes(this.tool.kind)) this.toolBeforeTakingAway = this.tool
      this.tool = chosenTool
    }
    this.pressCurrentTool()
    this.hidePointer()
    this.showBoardCursor()
  }

  // H chooses the hand, or leaves it (Anthony's request: with a mouse, holding space was a chore). Not while typing
  chooseHandWithKey(event) {
    if (isTyping(event) || event.ctrlKey || event.metaKey || event.altKey) return

    this.toolTargets.find((button) => button.dataset.toolKind === "hand")?.click()
  }

  firstFloorTool() {
    return toolOf(this.toolTargets.find((button) => button.dataset.toolKind === "floor"))
  }

  pressCurrentTool() {
    this.toolTargets.forEach((button) => {
      const isCurrent = button.dataset.toolKind === this.tool.kind && button.dataset.toolKey === this.tool.key
      button.setAttribute("aria-pressed", isCurrent)
    })
    this.showBoardCursor()
  }

  // The middle button, the space bar held, the hand, or the main button on a map played on a picture (nothing to draw
  // there but the blocked zones)
  movesTheMap(event) {
    if (event.button === 1 || this.isSpaceHeld) return true

    return event.button === 0 && (this.tool.kind === "hand" || this.picturePansTheMap())
  }

  picturePansTheMap() {
    return this.layout.isPicture() && this.tool.kind !== "blocker"
  }

  // A hand over the map while it can be moved (the hand, the space bar held, a map played on a picture), a closed
  // hand while it moves, the cross of drawing otherwise
  showBoardCursor() {
    const movesTheMap = this.tool.kind === "hand" || this.isSpaceHeld || this.picturePansTheMap()
    this.boardTarget.style.cursor = this.panningFrom ? "grabbing" : (movesTheMap ? "grab" : "")
  }

  // One finger or the main button draws; a second finger turns the stroke into a pinch; the middle button, or the
  // space bar held, moves the map
  startStroke(event) {
    this.boardTarget.setPointerCapture(event.pointerId)
    this.activePointers.set(event.pointerId, [event.clientX, event.clientY])
    if (this.activePointers.size === 2) return this.startPinch()
    // On a picture there is nothing to draw: dragging moves the map
    if (this.movesTheMap(event)) {
      // The middle button would otherwise start the scrolling of the browser
      event.preventDefault()
      this.panningFrom = [event.clientX, event.clientY]
      this.showBoardCursor()
      return
    }
    if (event.button !== 0) return

    this.stroke = { changed: false, removing: null, hasApplied: false, before: this.layout.snapshot() }
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
    this.showBoardCursor()
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

    this.useGridSize(this.layout.restore(snapshot))
    this.render()
    this.showHistory()
    this.save()
  }

  // Each map ready to use of the tab Templates drawn in its little board, on the paper of the maps
  drawPresetPreviews() {
    this.presetPreviewTargets.forEach((preview) => {
      const { columns, rows, layout } = presetOf(preview)
      preview.style.backgroundColor = voidGround
      renderMap(preview, { grid: new SquareGrid(columns, rows), floors: new Map(Object.entries(layout.floors)),
                           edges: new Map(Object.entries(layout.edges)), objects: layout.objects })
    })
  }

  // A map ready to use replaces the drawing, its grid with it: asked first when something is drawn, undone like a
  // stroke, then saved
  async usePreset(event) {
    const button = event.currentTarget
    const preset = presetOf(button)
    const question = this.replaceQuestionValue.replace("__name__", button.dataset.mapPresetName)
    if (!this.layout.isEmpty() && !(await confirmWithDialog(question, button))) return

    const before = this.layout.snapshot()
    this.useGridSize(this.layout.restore(JSON.stringify(preset)))
    this.gridRatio = preset.rows / preset.columns
    this.render()
    this.keepChange(before)
    this.showWholeMap()
  }

  // Drawn or on a picture: the drawing is kept either way, the change is undone like a stroke
  chooseMaking(event) {
    const before = this.layout.snapshot()
    this.layout.mode = event.target.value
    if (this.layout.isPicture() && !this.layout.picture) this.layout.picture = defaultPicture(this.grid)
    this.render()
    this.keepChange(before)
  }

  // The switch of the bar, the panel and the tools of the drawing follow the way the map is made (after an undo too)
  showMaking() {
    const isPicture = this.layout.isPicture()
    this.makingChoiceTargets.forEach((choice) => { choice.checked = choice.value === this.layout.mode })
    this.drawingPanelTarget.hidden = isPicture
    this.picturePanelTarget.hidden = !isPicture
    this.drawingToolsTarget.toggleAttribute("data-picture", isPicture)
    this.showBoardCursor()
    this.showPictureSettings()
  }

  showPictureSettings() {
    const picture = this.layout.picture
    if (!picture || !this.hasPictureWidthTarget) return

    if (document.activeElement !== this.pictureWidthTarget) this.pictureWidthTarget.value = picture.cells_wide
    this.pictureSliderTargets.forEach((slider) => {
      const { bounds, toSlider } = sliders[slider.dataset.setting]
      const [lowest, highest] = bounds(this.grid)
      Object.assign(slider, { min: lowest, max: highest })
      slider.value = toSlider(picture[slider.dataset.setting])
    })
  }

  // A setting moved: drawn at once, kept as one step of the history once let go (keepPictureSetting)
  changePictureSetting(event) {
    this.pictureBefore ??= this.layout.snapshot()
    const field = event.target
    if (field === this.pictureWidthTarget) {
      this.layout.picture = withCellsWide(this.layout.picture, Number(field.value))
    } else {
      this.layout.picture = { ...this.layout.picture,
                              [field.dataset.setting]: sliders[field.dataset.setting].fromSlider(Number(field.value)) }
    }
    this.render()
  }

  keepPictureSetting() {
    if (!this.pictureBefore) return

    this.keepChange(this.pictureBefore)
    this.pictureBefore = null
    this.showPictureSettings()
  }

  narrowPicture() {
    this.changePicture((picture) => withCellsWide(picture, picture.cells_wide - 1))
  }

  widenPicture() {
    this.changePicture((picture) => withCellsWide(picture, picture.cells_wide + 1))
  }

  centerPicture() {
    if (!this.pictureRatio) return

    this.changePicture((picture) => centered(picture, this.grid, this.pictureRatio))
  }

  // As wide as the grid, from its top left corner (its opacity kept)
  fitPicture() {
    this.changePicture((picture) => ({ ...defaultPicture(this.grid), opacity: picture.opacity }))
  }

  changePicture(change) {
    const before = this.layout.snapshot()
    this.layout.picture = change(this.layout.picture)
    this.render()
    this.keepChange(before)
  }

  // Asked first in the window of the app (Anthony's request), though Undo brings it all back
  async clearEverything() {
    if (this.layout.isEmpty()) return
    if (!(await confirmWithDialog(this.clearQuestionValue, this.clearButtonTarget))) return

    const before = this.layout.snapshot()
    this.layout.clear()
    this.render()
    this.keepChange(before)
  }

  addColumn() {
    this.columnsInputTarget.value = this.grid.columns + 1
    this.resizeGrid()
  }

  removeColumn() {
    this.columnsInputTarget.value = this.grid.columns - 1
    this.resizeGrid()
  }

  // The columns typed, the rows following the proportions, both within the bounds of a grid. The drawing stays in
  // the middle: the grid grows, or shrinks, on every side
  async resizeGrid() {
    const { columns, rows } = this.sizeFor(Number.parseInt(this.columnsInputTarget.value, 10))
    if (columns === this.grid.columns && rows === this.grid.rows) return this.showSize()

    const shift = this.layout.shiftFor(columns, rows)
    const losesSomething = this.layout.hasSomethingOutside(columns, rows, shift)
    if (losesSomething && !(await confirmWithDialog(this.shrinkQuestionValue, this.columnsInputTarget))) {
      return this.showSize()
    }
    const before = this.layout.snapshot()
    this.layout.moveBy(shift)
    this.layout.cropTo(new SquareGrid(columns, rows))
    this.useGridSize({ columns, rows })
    this.render()
    this.keepChange(before)
  }

  sizeFor(typedColumns) {
    const fewestColumns = Math.max(smallestGridSize, Math.ceil(smallestGridSize / this.gridRatio))
    const mostColumns = Math.min(largestGridSize, Math.floor(largestGridSize / this.gridRatio))
    const columns = Math.min(mostColumns, Math.max(fewestColumns, typedColumns || this.grid.columns))
    return { columns, rows: Math.round(columns * this.gridRatio) }
  }

  // A new grid (resized, or given back by undo): the whole map shown again
  useGridSize({ columns, rows }) {
    if (columns !== this.grid.columns || rows !== this.grid.rows) {
      this.grid = new SquareGrid(columns, rows)
      this.layout.grid = this.grid
      this.view = new BoardView(this.grid)
      this.resizeView()
    }
    this.showSize()
  }

  showSize() {
    this.columnsInputTarget.value = this.grid.columns
    this.rowsCountTarget.textContent = this.grid.rows
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
    if (this.layout.isPicture()) {
      renderPicture(this.drawingTarget, { grid: this.grid, url: this.pictureUrlValue, picture: this.layout.picture,
                                          ratio: this.pictureRatio })
    } else {
      renderMap(this.drawingTarget, { grid: this.grid, floors: this.layout.floors, edges: this.layout.edges,
                                      objects: this.layout.objects })
    }
    renderBlockedCells(this.drawingTarget, this.layout.blocked)
    this.showMaking()
    this.showFigures()
  }

  // The direction of the next object put, a quarter turn more each time (the button of the bar, or R)
  rotatePlacement() {
    this.placementRotation = (this.placementRotation + 1) % 4
    this.showRotation()
  }

  rotateWithKey(event) {
    if (isTyping(event) || event.ctrlKey || event.metaKey || event.altKey) return

    this.rotatePlacement()
  }

  showRotation() {
    this.rotationLabelTarget.title = this.rotationLabelValue.replace("__degrees__", this.placementRotation * 90)
  }

  // A right click takes away the object under the pointer, or the wall of a side close to it
  deleteWithRightClick(event) {
    event.preventDefault()
    this.deleteAt(this.boardPoint(event))
  }

  // Delete or Backspace (Stimulus knows neither as a key filter of an action: checked here)
  deleteWithKey(event) {
    if (!deletingKeys.includes(event.key)) return
    if (!this.isPointerOverBoard || !this.lastPoint || isTyping(event)) return

    event.preventDefault()
    this.deleteAt(this.lastPoint)
  }

  deleteAt(point) {
    const side = this.grid.nearestSide(point)
    const before = this.layout.snapshot()
    const isDeleted = this.layout.removeObjectAt(side.column, side.row) ||
      (side.distance < deletingReach && this.layout.removeEdge(side))
    if (!isDeleted) return

    this.render()
    this.keepChange(before)
  }

  // « 120 cases · 14 murs · 3 portes », in the plural rules of the language of the page
  // Not for a map played on a picture: they count the drawing, kept aside
  showFigures() {
    this.figuresTarget.hidden = this.layout.isPicture()
    const doorCount = [...this.layout.edges.values()].filter((edgeKey) => edgeKey === doorKey).length
    const counts = { cells: this.layout.floors.size, walls: this.layout.edges.size - doorCount, doors: doorCount,
                     objects: this.layout.objects.length }
    const pluralRules = new Intl.PluralRules(document.documentElement.lang || "en")
    this.figuresTarget.textContent = Object.entries(counts).map(([figure, count]) => {
      const labels = this.figureLabelsValue[figure]
      return (labels[pluralRules.select(count)] ?? labels.other).replace("%{count}", count)
    }).join(" · ")
  }

  applyTool(event) {
    const side = this.grid.nearestSide(this.boardPoint(event))
    if (!this.grid.inside(side.column, side.row)) return

    const isFirstCell = !this.stroke.hasApplied
    this.stroke.hasApplied = true
    if (!this.changeLayout(side, isFirstCell)) return

    this.stroke.changed = true
    this.render()
  }

  // A floor paints its cell, the eraser takes a wall or a floor. A wall or a door: the first side of the stroke says
  // whether the stroke puts that wall, or takes it away from the sides that hold it already
  changeLayout(side, isFirstCell) {
    if (this.tool.kind === "floor") return this.layout.paintFloor(side.column, side.row, this.tool.key)
    if (this.tool.kind === "blocker") return this.paintBlocked(side)
    if (this.tool.kind === "eraser") return this.layout.erase(side)
    if (this.tool.kind === "remover") return this.layout.removeObjectAt(side.column, side.row)
    if (this.tool.kind === "object") return this.putObject(side, isFirstCell)
    if (!this.mayHoldEdge(side)) return false

    this.stroke.removing ??= this.layout.hasEdge(side, this.tool.key)
    return this.stroke.removing ? this.layout.removeEdge(side) : this.layout.putEdge(side, this.tool.key)
  }

  // The first cell of the stroke says whether it paints the blocked zones, or takes them away
  paintBlocked({ column, row }) {
    this.stroke.removing ??= this.layout.isBlocked(column, row)
    return this.stroke.removing ? this.layout.unblock(column, row) : this.layout.block(column, row)
  }

  // On an object put, the first cell of the stroke turns it. A small object is put on every cell of the stroke, a large
  // one only where the stroke starts
  putObject(side, isFirstCell) {
    if (this.layout.objectAt(side.column, side.row)) {
      return isFirstCell && this.layout.turnObjectAt(side.column, side.row)
    }
    const mapObject = objectOf(this.tool.key)
    if (!isFirstCell && (mapObject.width > 1 || mapObject.height > 1)) return false

    return this.layout.placeObject({ key: this.tool.key, column: side.column, row: side.row,
                                     rotation: this.placementRotation })
  }

  // Not on the edge of the grid: the cell across it is outside, and the server would refuse the drawing
  mayHoldEdge(side) {
    return this.grid.inside(side.neighbourColumn, side.neighbourRow) && this.layout.mayHoldEdge(side, this.tool.key)
  }

  // Where the tool would act: the cell, or the side for a wall, in red where a wall cannot stand
  markPointer(event) {
    this.hidePointer()
    if (this.picturePansTheMap() || this.tool.kind === "hand") return

    this.isPointerOverBoard = true
    this.lastPoint = this.boardPoint(event)
    const side = this.grid.nearestSide(this.lastPoint)
    if (!this.grid.inside(side.column, side.row)) return

    if (this.tool.kind === "edge") return this.markSide(side)
    if (this.tool.kind === "object" || this.tool.kind === "remover") return this.markObject(side)
    this.markCells([[side.column, side.row]], allowedMark)
  }

  // On an object put: its cells (in red for Take object away). Elsewhere, the object to put, faded, on its cells
  markObject(side) {
    const objectThere = this.layout.objectAt(side.column, side.row)
    if (objectThere) {
      return this.markCells(this.layout.cellsOf(objectThere), this.tool.kind === "remover" ? refusedMark : allowedMark)
    }
    if (this.tool.kind === "remover") return this.markCells([[side.column, side.row]], allowedMark)

    const placedObject = { key: this.tool.key, column: side.column, row: side.row, rotation: this.placementRotation }
    const mayPlace = this.layout.mayPlace(placedObject)
    this.markCells(this.layout.cellsOf(placedObject).filter(([column, row]) => this.grid.inside(column, row)),
                   mayPlace ? allowedMark : refusedMark)
    if (!mayPlace) return

    const mapObject = objectOf(this.tool.key)
    const [centerX, centerY] = objectCenter(placedObject, mapObject)
    drawPlacedObject(createSvgElement("g", { opacity: 0.45 }, this.pointerMarksTarget), placedObject, mapObject,
                     centerX, centerY)
  }

  markCells(cells, color) {
    cells.forEach(([column, row]) => createSvgElement("path", {
      d: polygonPath(this.grid.corners(column, row)), fill: color, "fill-opacity": 0.12, stroke: color,
      "stroke-width": 1.5, "stroke-dasharray": "3 3"
    }, this.pointerMarksTarget))
  }

  markSide(side) {
    const { start, end } = this.grid.side(side.column, side.row, side.sideIndex)
    const color = this.mayHoldEdge(side) ? allowedMark : refusedMark
    createSvgElement("line", { x1: rounded(start[0]), y1: rounded(start[1]), x2: rounded(end[0]), y2: rounded(end[1]),
                               stroke: color, "stroke-width": 4, "stroke-opacity": 0.6, "stroke-linecap": "round" },
                     this.pointerMarksTarget)
  }

  // From the view itself rather than getScreenCTM, which some browsers count wrong on a board resized or rounded:
  // the zoom then went around the wrong point, and the map drifted off the middle
  boardPoint(event) {
    const board = this.boardTarget.getBoundingClientRect()
    return this.view.pointAt(event.clientX - board.left, event.clientY - board.top)
  }

  // One save at a time, so that an older drawing never arrives last: a stroke made meanwhile is sent once it is back
  async save() {
    if (this.isSaving) {
      this.hasUnsavedStroke = true
      return
    }
    this.isSaving = true
    this.hasUnsavedStroke = false
    this.showSaveState(this.savingLabelValue)
    const isSaved = await this.request().then((response) => response.ok, () => false)
    this.isSaving = false
    this.statusTarget.textContent = isSaved ? "" : this.saveFailedMessageValue
    this.showSaveState(isSaved ? this.savedLabelValue.replace("__time__", currentTime()) : "")
    if (this.hasUnsavedStroke) this.save()
  }

  // « Enregistrement… », then « Enregistré à 14:32 », kept through a refresh by morphing (renaming)
  showSaveState(text) {
    this.lastSaveState = text
    this.saveStateTarget.textContent = text
  }

  // keepalive: the last stroke is still saved when the page is left right after it
  request() {
    const body = new FormData()
    body.append("layout", JSON.stringify(this.layout.toJSON()))
    body.append("columns", this.grid.columns)
    body.append("rows", this.grid.rows)
    return fetch(this.urlValue, {
      method: "PATCH",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content, Accept: "application/json" }
    })
  }
}

// A touchpad slides in pixels, often sideways too, and Chrome and Safari give it a wheelDeltaY of exactly -3 times its
// deltaY; a mouse wheel turns by lines (Firefox) or by notches that do not follow that rule. Firefox gives no
// wheelDeltaY: in pixels there, it is a touchpad
function isTouchpadSlide(event) {
  if (event.deltaMode === WheelEvent.DOM_DELTA_LINE) return false
  if (event.deltaX !== 0) return true
  if (event.wheelDeltaY === undefined) return true

  return event.wheelDeltaY === -3 * event.deltaY
}

// How far the wheel turned, in pixels: Firefox counts a mouse wheel in lines (about 3 a notch), which hardly zoomed
function wheelPixels(event) {
  return event.deltaMode === WheelEvent.DOM_DELTA_LINE ? event.deltaY * pixelsPerWheelLine : event.deltaY
}

// The size of the grid and the drawing of a map ready to use, carried by its item (map_templates/_preset_tools)
function presetOf(element) {
  return JSON.parse(element.closest("[data-map-preset]").dataset.mapPreset)
}

function isTyping(event) {
  return Boolean(event.target.closest?.("input, textarea, select, [contenteditable]"))
}

// Hours and minutes in the language of the page
function currentTime() {
  return new Intl.DateTimeFormat(document.documentElement.lang || "en", { hour: "2-digit", minute: "2-digit" })
    .format(new Date())
}

function isSameTool(first, second) {
  return first.kind === second.kind && first.key === second.key
}

function toolOf(button) {
  return { kind: button.dataset.toolKind, key: button.dataset.toolKey }
}
