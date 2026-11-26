import { Controller } from "@hotwired/stimulus"
import SquareGrid from "map_editor/square_grid"
import BoardView from "map_editor/board_view"
import DrawingHistory from "map_editor/drawing_history"
import MapLayout from "map_editor/map_layout"
import { renderMap, objectCenter, drawPlacedObject } from "map_editor/map_renderer"
import { renderPicture } from "map_editor/picture_renderer"
import { renderBlockedCells, renderNaturalBlocks } from "map_editor/blocked_renderer"
import { naturalBlocks } from "map_editor/passage"
import { renderTokens, drawToken } from "map_editor/token_renderer"
import { drawFloorSample } from "map_editor/floor_sample"
import { defaultPicture, fittedPicture, isFitted, rowsOverPicture, sliders } from "map_editor/picture_settings"
import { addMapPatterns } from "map_editor/patterns"
import { isTouchpadSlide, wheelPixels, pinchShape } from "map_editor/gestures"
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
// chosen by Turn (R); a click on an object put turns it; Take object away or Delete takes it (or a wall) away; a
// right click puts the tool down. The number of columns of the bar resizes the grid, the rows following to keep its
// proportions (Anthony's request): cells added or taken away on the right and at the bottom, asked first when something drawn would go,
// undone like a stroke. The bar says when the drawing was saved. On a map of a table, the brush « Zones bloquantes »
// paints the cells no token stands on, drawn or on a picture (the first cell of the stroke says whether it paints or
// takes the paint away), and the tab Jetons puts the tokens of its non-player characters and enemies (one a cell, never
// on a cell blocked or without floor, the same character as many times as wanted; a token clicked again goes), or of
// any creature of the bestiary, copied into the table when its first token is put (the server copies it; its band then
// shares the copy). The board and the tools are rendered hidden and shown here: without JavaScript there is nothing
// to draw with
const toolSwatches = {
  floor: (swatch, key) => drawFloorSample(swatch, key),
  edge: (swatch, key) => edgeOf(key).drawSwatch(swatch),
  object: (swatch, key) => drawObjectSwatch(swatch, key),
  token: (swatch, key, characters) => {
    swatch.setAttribute("viewBox", "0 0 24 24")
    drawToken(swatch, 12, 12, characters[key] ?? { name: swatch.dataset.toolName, kind: "monster" })
  },
  creature: (swatch) => {
    swatch.setAttribute("viewBox", "0 0 24 24")
    drawToken(swatch, 12, 12, { name: swatch.dataset.toolName, kind: "monster" })
  }
}
// The tools that act on a map played on a picture: elsewhere, dragging on it moves the map
const toolsOnPicture = ["blocker", "token", "creature"]
// How close to a side Delete must be to take its wall away
const deletingReach = 6
// No tool in hand, after a right click (Anthony's request: a chair put, no more chairs): a click does nothing
const noTool = { kind: "none" }
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
const clickTolerance = 5

export default class extends Controller {
  static targets = ["board", "drawing", "pointerMarks", "toolbar", "tool", "swatch", "status", "figures",
                     "undoButton", "redoButton", "clearButton", "rotationLabel", "columnsInput", "rowsCount",
                     "saveState", "zoomButtons", "presetPreview", "makingChoice", "drawingPanel", "picturePanel",
                     "drawingTools", "cellPixels", "pictureSlider", "gridSize", "tableTokens", "tableTokensEmpty",
                     "tokenTemplate", "brushSize", "tokenMenu", "tokenMenuTitle", "tokenStateChoice"]
  static values = { layout: Object, columns: Number, rows: Number, url: String, saveFailedMessage: String,
                    figureLabels: Object, rotationLabel: String, savingLabel: String, savedLabel: String,
                    shrinkQuestion: String, clearQuestion: String, replaceQuestion: String, pictureUrl: String,
                    tokenCharacters: Object, creatureUrl: String, copyFailedMessage: String }

  connect() {
    this.grid = new SquareGrid(this.columnsValue, this.rowsValue)
    this.layout = new MapLayout(this.layoutValue, this.grid)
    this.placementRotation = 0
    this.brushSize = 1
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
  // A picture sent while the editor is open (the page refreshed by morphing) lays the grid over it at once
  pictureUrlValueChanged() {
    this.pictureRatio = null
    this.pictureWidthInPixels = null
    if (!this.pictureUrlValue) return this.layout && this.render()

    const isNewPicture = Boolean(this.layout)
    const picture = new Image()
    picture.addEventListener("load", () => {
      this.pictureRatio = picture.naturalHeight / picture.naturalWidth
      this.pictureWidthInPixels = picture.naturalWidth
      if (!this.layout) return
      if (isNewPicture && this.pictureFollowsGrid()) return this.changeGridSize(this.grid.columns)

      this.render()
      this.showPictureSettings()
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
      toolSwatches[swatch.dataset.toolKind](swatch, swatch.dataset.toolKey, this.tokenCharactersValue)
    })
    this.drawPresetPreviews()
    this.showRotation()
    this.showSize()
    this.saveStateTarget.textContent = this.lastSaveState ?? ""
    this.pressCurrentTool()
    this.pressBrushSize()
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

  // How far the map may move past its edges: as far as the floating pieces reach into the board (the size of the grid
  // at the top, the help and the zoom on the right, what was saved at the bottom), a little room beyond them so that
  // a cell is not drawn against their edge. The same margin on the four sides (decision: the map moved past its top
  // and right edges, but not past the bottom, where nothing floats on a map played on a picture, nor the left)
  floatingInsets() {
    const board = this.boardTarget.getBoundingClientRect()
    const reach = (element, side) => {
      if (!element || element.offsetParent === null) return 0

      const piece = element.getBoundingClientRect()
      const distance = { top: piece.bottom - board.top, right: board.right - piece.left,
                         bottom: board.bottom - piece.top }[side]
      return Math.max(0, distance + floatingRoom)
    }
    const margin = Math.max(reach(this.gridSizeTarget, "top"), reach(this.zoomButtonsTarget.parentElement, "right"),
                            reach(this.figuresTarget.parentElement, "bottom"))
    return { top: margin, right: margin, bottom: margin, left: margin }
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
      return this.useTool(this.toolBeforeTakingAway ?? this.firstFloorTool())
    }
    if (!toolsLeftByClickingAgain.includes(this.tool.kind)) this.toolBeforeTakingAway = this.tool
    this.useTool(chosenTool)
  }

  // A right click on the map puts the tool down: nothing is pressed on the bar, a click does nothing
  dropToolWithRightClick(event) {
    event.preventDefault()
    this.finishStroke()
    this.useTool(noTool)
  }

  useTool(tool) {
    this.closeTokenMenu()
    this.tool = tool
    this.pressCurrentTool()
    this.hidePointer()
    this.showBoardCursor()
    // What blocks by itself shows while the blocked zones are painted
    if (tool.kind === "blocker" || this.wasPaintingBlocked) this.render()
    this.wasPaintingBlocked = tool.kind === "blocker"
  }

  // H chooses the hand, or leaves it (Anthony's request: with a mouse, holding space was a chore). Not while typing
  chooseHandWithKey(event) {
    if (isTyping(event) || event.ctrlKey || event.metaKey || event.altKey) return

    this.toolTargets.find((button) => button.dataset.toolKind === "hand")?.click()
  }

  firstFloorTool() {
    return toolOf(this.toolTargets.find((button) => button.dataset.toolKind === "floor"))
  }

  // The side of the square a floor paints at each cell; the walls and the objects stay one cell at a time
  chooseBrushSize(event) {
    this.brushSize = Number(event.currentTarget.dataset.brushSize)
    this.pressBrushSize()
  }

  pressBrushSize() {
    this.brushSizeTargets.forEach((button) => {
      button.setAttribute("aria-pressed", Number(button.dataset.brushSize) === this.brushSize)
    })
  }

  // The square of the brush around the cell aimed at (a little more to the right and below for an even side), cut by
  // the edges of the grid
  floorBrushCells({ column, row }) {
    const firstOffset = -Math.floor((this.brushSize - 1) / 2)
    const offsets = Array.from({ length: this.brushSize }, (_, index) => firstOffset + index)
    return offsets.flatMap((rowOffset) => offsets.map((columnOffset) => [column + columnOffset, row + rowOffset]))
      .filter(([brushColumn, brushRow]) => this.grid.inside(brushColumn, brushRow))
  }

  paintFloorBrush(side) {
    const paintedCells = this.floorBrushCells(side)
      .filter(([column, row]) => this.layout.paintFloor(column, row, this.tool.key))
    return paintedCells.length > 0
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
    return this.layout.isPicture() && !toolsOnPicture.includes(this.tool.kind)
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
    this.closeTokenMenu()
    if (this.tool === noTool && event.button === 0) this.tokenPressedAt = [event.clientX, event.clientY]
    // On a picture there is nothing to draw: dragging moves the map
    if (this.movesTheMap(event)) {
      // The middle button would otherwise start the scrolling of the browser
      event.preventDefault()
      this.panningFrom = [event.clientX, event.clientY]
      this.showBoardCursor()
      return
    }
    if (event.button !== 0 || this.tool === noTool) return

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
    if (this.tokenPressedAt) this.openTokenMenuAfterPress(event)
  }

  openTokenMenuAfterPress(event) {
    const [pressedX, pressedY] = this.tokenPressedAt
    this.tokenPressedAt = null
    if (!this.hasTokenMenuTarget || Math.hypot(event.clientX - pressedX, event.clientY - pressedY) > clickTolerance) {
      return
    }

    const [column, row] = this.grid.cellAt(...this.boardPoint(event))
    if (this.layout.tokenAt(column, row)) this.openTokenMenu(column, row, event)
  }

  openTokenMenu(column, row, event) {
    const token = this.layout.tokenAt(column, row)
    this.tokenMenuCell = [column, row]
    this.tokenMenuTitleTarget.textContent = this.tokenCharactersValue[token.character_id]?.name ?? ""
    const startsHidden = this.layout.tokenStartsHidden(column, row)
    this.tokenStateChoiceTargets.forEach((choice) => {
      choice.setAttribute("aria-checked", String((choice.dataset.hidden === "true") === startsHidden))
    })
    this.placeTokenMenuAt(event)
    this.tokenMenuTarget.hidden = false
    this.tokenStateChoiceTargets.find((choice) => choice.ariaChecked === "true")?.focus({ focusVisible: false })
  }

  placeTokenMenuAt(event) {
    const room = this.tokenMenuTarget.parentElement.getBoundingClientRect()
    const menuWidth = this.tokenMenuTarget.offsetWidth || 256
    const left = Math.min(event.clientX - room.left + floatingRoom, room.width - menuWidth - floatingRoom)
    this.tokenMenuTarget.style.left = `${Math.max(floatingRoom, left)}px`
    this.tokenMenuTarget.style.top = `${event.clientY - room.top}px`
  }

  chooseTokenState(event) {
    const [column, row] = this.tokenMenuCell
    const before = this.layout.snapshot()
    if (this.layout.startTokenHidden(column, row, event.currentTarget.dataset.hidden === "true")) {
      this.render()
      this.keepChange(before)
    }
    this.closeTokenMenu()
  }

  closeTokenMenu() {
    this.tokenMenuCell = null
    if (this.hasTokenMenuTarget) this.tokenMenuTarget.hidden = true
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

    this.closeTokenMenu()
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

  // Drawn or on a picture: the drawing is kept either way, the change is undone like a stroke. On a picture, the grid
  // is laid over it, in the same step
  async chooseMaking(event) {
    const before = this.layout.snapshot()
    this.layout.mode = event.target.value
    if (this.layout.isPicture() && !this.layout.picture) this.layout.picture = defaultPicture(this.grid)
    if (this.pictureFollowsGrid() && (await this.changeGridSize(this.grid.columns, before))) return

    this.render()
    this.keepChange(before)
  }

  // On a map played on a picture whose proportions are known, the grid follows the picture (Anthony's request): the
  // rows follow its proportions, the picture covers the whole grid, the number of cells across is all one chooses
  pictureFollowsGrid() {
    return this.layout.isPicture() && Boolean(this.pictureRatio)
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
    if (!picture) return

    this.pictureSliderTargets.forEach((slider) => {
      const { bounds, toSlider } = sliders[slider.dataset.setting]
      const [lowest, highest] = bounds(this.grid)
      Object.assign(slider, { min: lowest, max: highest })
      slider.value = toSlider(picture[slider.dataset.setting])
    })
    this.showCellPixels()
  }

  // "Une case fait environ 71 px de l'image.": the measure the makers of battle maps give (70 px per cell)
  showCellPixels() {
    if (!this.hasCellPixelsTarget) return

    const pixels = this.pictureWidthInPixels && Math.round(this.pictureWidthInPixels / this.grid.columns)
    this.cellPixelsTarget.hidden = !pixels
    if (pixels) this.cellPixelsTarget.textContent = this.cellPixelsTarget.dataset.template.replace("%{pixels}", pixels)
  }

  // A setting moved: drawn at once, kept as one step of the history once let go (keepPictureSetting)
  changePictureSetting(event) {
    this.pictureBefore ??= this.layout.snapshot()
    const slider = event.target
    this.layout.picture = { ...this.layout.picture,
                            [slider.dataset.setting]: sliders[slider.dataset.setting].fromSlider(Number(slider.value)) }
    this.render()
  }

  keepPictureSetting() {
    if (!this.pictureBefore) return

    this.keepChange(this.pictureBefore)
    this.pictureBefore = null
    this.showPictureSettings()
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

  resizeGrid() {
    this.changeGridSize(Number.parseInt(this.columnsInputTarget.value, 10))
  }

  // The columns given, the rows following the proportions, both within the bounds of a grid. A drawing stays in the
  // middle: the grid grows, or shrinks, on every side, and something that would go out is asked first. On a picture,
  // the grid grows from its top left corner and the picture with it, over the whole grid: nothing asked (Anthony's
  // request: the picture is never cut), what goes out (tokens, painted zones, the drawing kept for Draw) is taken out
  // all the same, Undo brings it back. before: the state the step starts from (choosing to play on a picture lays the
  // grid in the same step). Whether the grid was changed
  async changeGridSize(typedColumns, before = this.layout.snapshot()) {
    const { columns, rows } = this.sizeFor(typedColumns)
    const pictureToFit = this.pictureFollowsGrid() && !isFitted(this.layout.picture, columns)
    if (columns === this.grid.columns && rows === this.grid.rows && !pictureToFit) {
      this.showSize()
      return false
    }
    const shift = this.pictureFollowsGrid() ? [0, 0] : this.layout.shiftFor(columns, rows)
    const asksFirst = !this.pictureFollowsGrid() && this.layout.hasSomethingOutside(columns, rows, shift)
    if (asksFirst && !(await confirmWithDialog(this.shrinkQuestionValue, this.columnsInputTarget))) {
      this.showSize()
      return false
    }
    this.layout.moveBy(shift)
    this.layout.cropTo(new SquareGrid(columns, rows))
    if (this.pictureFollowsGrid()) this.layout.picture = fittedPicture(this.layout.picture, columns)
    this.useGridSize({ columns, rows })
    this.render()
    this.keepChange(before)
    return true
  }

  sizeFor(typedColumns) {
    const ratio = this.pictureFollowsGrid() ? this.pictureRatio : this.gridRatio
    const rowsFor = (columns) => {
      return this.pictureFollowsGrid() ? rowsOverPicture(columns, ratio) : Math.round(columns * ratio)
    }
    const fewestColumns = Math.max(smallestGridSize, Math.ceil(smallestGridSize / ratio))
    const mostColumns = Math.min(largestGridSize, Math.floor(largestGridSize / ratio))
    const columns = Math.min(mostColumns, Math.max(fewestColumns, typedColumns || this.grid.columns))
    return { columns, rows: rowsFor(columns) }
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
    this.showCellPixels()
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
    this.pinch = pinchShape(this.activePointers)
  }

  continuePinch() {
    const shape = pinchShape(this.activePointers)
    this.view.zoomAround(this.boardPoint({ clientX: shape.middle[0], clientY: shape.middle[1] }),
                         shape.distance / this.pinch.distance)
    this.view.moveByPixels(shape.middle[0] - this.pinch.middle[0], shape.middle[1] - this.pinch.middle[1])
    this.pinch = shape
    this.showView()
  }

  render() {
    if (this.layout.isPicture()) {
      renderPicture(this.drawingTarget, { grid: this.grid, url: this.pictureUrlValue, picture: this.layout.picture,
                                          ratio: this.pictureRatio })
    } else {
      renderMap(this.drawingTarget, { grid: this.grid, floors: this.layout.floors, edges: this.layout.edges,
                                      objects: this.layout.objects })
    }
    if (this.tool.kind === "blocker" && !this.layout.isPicture()) {
      renderNaturalBlocks(this.drawingTarget, this.grid, naturalBlocks({ grid: this.grid, floors: this.layout.floors,
                                                                          edges: this.layout.edges }))
    }
    renderBlockedCells(this.drawingTarget, this.layout.blocked)
    renderTokens(this.drawingTarget, this.layout.tokens, this.tokenCharactersValue)
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

  // Delete or Backspace take away the token or the object under the pointer, or the wall of a side close to it
  // (Stimulus knows neither as a key filter of an action: checked here)
  deleteWithKey(event) {
    if (!deletingKeys.includes(event.key)) return
    if (!this.isPointerOverBoard || !this.lastPoint || isTyping(event)) return

    event.preventDefault()
    this.deleteAt(this.lastPoint)
  }

  deleteAt(point) {
    const side = this.grid.nearestSide(point)
    const before = this.layout.snapshot()
    const isDeleted = this.layout.removeTokenAt(side.column, side.row) ||
      this.layout.removeObjectAt(side.column, side.row) ||
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
    if (this.tool.kind === "floor") return this.paintFloorBrush(side)
    if (this.tool.kind === "blocker") return this.paintBlocked(side)
    if (this.tool.kind === "token") return this.putToken(side)
    if (this.tool.kind === "creature") return this.putCreature(side, isFirstCell)
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

  // Like the blocked zones: a stroke that starts on a token takes tokens away, otherwise it puts one on each free cell
  putToken({ column, row }) {
    this.stroke.removing ??= Boolean(this.layout.tokenAt(column, row))
    if (this.stroke.removing) return this.layout.removeTokenAt(column, row)

    return this.layout.placeToken(Number(this.tool.key), column, row)
  }

  // A creature of the bestiary: copied into the table by the server on the first cell of the stroke, then its token is
  // put (a stroke that starts on a token takes it away, like any token). Nothing changes until the copy comes back
  putCreature({ column, row }, isFirstCell) {
    if (!isFirstCell) return false
    if (this.layout.tokenAt(column, row)) return this.layout.removeTokenAt(column, row)
    if (!this.layout.mayHoldToken(column, row)) return false

    this.copyCreature(this.tool.key, column, row)
    return false
  }

  // One copy at a time. The copy joins the list of the table, and becomes the tool: the next tokens of its band share it
  async copyCreature(creatureKey, column, row) {
    if (this.isCopying) return

    this.isCopying = true
    const body = new FormData()
    body.append("key", creatureKey)
    const response = await fetch(this.creatureUrlValue, { method: "POST", body, headers: jsonHeaders() })
      .catch(() => null)
    this.isCopying = false
    if (!response?.ok) {
      this.statusTarget.textContent = this.copyFailedMessageValue
      return
    }
    const character = await response.json()
    this.tokenCharactersValue = { ...this.tokenCharactersValue, [character.id]: { name: character.name, kind: character.kind } }
    this.addTableToken(character)
    this.tool = { kind: "token", key: String(character.id) }
    this.pressCurrentTool()
    const before = this.layout.snapshot()
    if (!this.layout.placeToken(character.id, column, row)) return

    this.render()
    this.keepChange(before)
  }

  // Its line in the list of the table, in both panels, made from the template of the page
  addTableToken({ id, name }) {
    this.tableTokensTargets.forEach((list, index) => {
      const line = this.tokenTemplateTargets[index].content.firstElementChild.cloneNode(true)
      line.dataset.searchName = name.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
      line.querySelectorAll("[data-tool-key]").forEach((element) => { element.dataset.toolKey = id })
      line.querySelector("[data-token-name]").textContent = name
      const swatch = line.querySelector("svg")
      swatch.dataset.toolName = name
      toolSwatches.token(swatch, String(id), this.tokenCharactersValue)
      list.append(line)
    })
    this.tableTokensEmptyTargets.forEach((empty) => { empty.hidden = true })
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
    if (!this.grid.inside(side.column, side.row) || this.tool === noTool) return

    if (this.tool.kind === "edge") return this.markSide(side)
    if (this.tool.kind === "object" || this.tool.kind === "remover") return this.markObject(side)
    if (this.tool.kind === "token" || this.tool.kind === "creature") return this.markToken(side)
    if (this.tool.kind === "floor") return this.markCells(this.floorBrushCells(side), allowedMark)
    this.markCells([[side.column, side.row]], allowedMark)
  }

  // Red where a token cannot stand; a token there is taken away
  markToken({ column, row }) {
    const isAllowed = Boolean(this.layout.tokenAt(column, row)) || this.layout.mayHoldToken(column, row)
    this.markCells([[column, row]], isAllowed ? allowedMark : refusedMark)
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
      headers: jsonHeaders()
    })
  }
}

// The size of the grid and the drawing of a map ready to use, carried by its item (map_templates/_preset_tools)
function presetOf(element) {
  return JSON.parse(element.closest("[data-map-preset]").dataset.mapPreset)
}

function jsonHeaders() {
  return { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content, Accept: "application/json" }
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
