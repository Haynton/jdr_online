import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { createSvgElement } from "map_editor/svg"
import { renderBoardTokens } from "map_editor/token_renderer"
import { passageOf, walkTowards, pathCost, sameCell } from "map_editor/board_moves"

const CELL_SIZE = 24
const ghostOpacity = 0.4
const clickMovementTolerance = 5
const menuGap = 8

export default class extends Controller {
  static targets = ["map", "tokens", "creaturePlacer", "hint", "hintName", "tokenMenu", "tokenMenuTitle",
                    "tokenVisibilityButton", "tokenRenameButton", "tokenRenameForm", "tokenNameInput", "moveBubble"]
  static values = { hint: String, playerHint: String, tokensUrl: String, showLabel: String, hideLabel: String,
                    gameMaster: Boolean, cellLength: Number, distanceLabel: String, cellsLabels: Object }

  mapTargetConnected() {
    this.drawTokens()
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
  }

  mapTargetDisconnected() {
    this.dropCreature()
    this.closeTokenMenu()
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
  }

  tokensTargetConnected() {
    this.closeTokenMenu()
    this.drawTokens()
    this.creaturePlacerTargets.forEach((button) => this.showCreaturePlacer(button))
    this.followTheDragAfterDrawing()
  }

  // The tokens drawn again during a drag (a message of the table): the drag goes on, unless someone else moved or took
  // away the token dragged
  followTheDragAfterDrawing() {
    const drag = this.tokenDrag
    if (!drag?.started) return

    const now = this.tokenData(String(drag.token.id))
    now && sameCell([now.column, now.row], drag.start) ? this.showDraggedToken(drag) : this.cancelTokenDrag()
  }

  creaturePlacerTargetConnected(button) {
    button.hidden = false
    this.showCreaturePlacer(button)
  }

  drawTokens() {
    if (!this.hasMapTarget || !this.hasTokensTarget) return

    renderBoardTokens(this.tokensLayer(), this.tokensOfTheMap())
  }

  // Between the message to all the players and the one to a player alone, a token may be in both: drawn once, as the
  // shared tokens say (they come first in the page)
  tokensOfTheMap() {
    const mapId = this.mapTarget.dataset.gameMapId
    const tokensById = new Map()
    this.tokensTargets
      .filter((element) => !element.dataset.gameMapId || element.dataset.gameMapId === mapId)
      .flatMap((element) => JSON.parse(element.dataset.tokens))
      .forEach((token) => { if (!tokensById.has(token.id)) tokensById.set(token.id, token) })
    return [...tokensById.values()]
  }

  tokensLayer() {
    const layer = this.mapTarget.querySelector("[data-board-tokens-layer]") ||
      createSvgElement("g", { "data-board-tokens-layer": "" })
    this.mapTarget.appendChild(layer)
    return layer
  }

  showCreaturePlacer(button) {
    button.title = this.placerTitle(button)
    button.setAttribute("aria-disabled", String(button.title !== button.dataset.placeLabel))
  }

  placerTitle(button) {
    if (!this.hasMapTarget) return button.dataset.needsMapLabel
    if (this.playerAlreadyPlaced(button)) return button.dataset.alreadyPlacedLabel

    return button.dataset.placeLabel
  }

  playerAlreadyPlaced(button) {
    if (button.dataset.roomBoardKindParam !== "pc" || !this.hasTokensTarget) return false

    const characterId = Number(button.dataset.roomBoardIdParam)
    return this.tokensOfTheMap().some((token) => token.character_id === characterId)
  }

  takeCreature(event) {
    if (event.currentTarget.getAttribute("aria-disabled") === "true") return
    if (this.creature?.id === event.params.id) return this.dropCreature()

    this.closeTokenMenu()
    this.creature = { id: event.params.id, name: event.params.name, kind: event.params.kind }
    this.pressCreaturePlacer(event.currentTarget)
    const hint = this.creature.kind === "pc" ? this.playerHintValue : this.hintValue
    this.hintNameTarget.textContent = hint.replace("__NAME__", this.creature.name)
    this.hintTarget.hidden = false
    this.element.setAttribute("data-placing", "")
  }

  dropCreature() {
    this.creature = null
    this.pressCreaturePlacer(null)
    if (this.hasHintTarget) this.hintTarget.hidden = true
    this.element.removeAttribute("data-placing")
  }

  pressCreaturePlacer(pressedButton) {
    this.creaturePlacerTargets.forEach((button) => button.setAttribute("aria-pressed", String(button === pressedButton)))
  }

  dropCreatureWithKeys() {
    if (document.querySelector("dialog[open]")) return

    this.closeTokenMenu()
    this.cancelTokenDrag()
    if (this.creature) this.dropCreature()
  }

  dropCreatureWithRightClick(event) {
    if (!this.creature) return

    event.preventDefault()
    this.dropCreature()
  }

  notePointerDown(event) {
    this.pointerDownAt = [event.clientX, event.clientY]
  }

  clickBoard(event) {
    if (this.pointerMovedSinceDown(event) || this.mapTarget.closest("[data-moving-map]")) return
    if (this.creature) return this.placeCreature(event)

    const token = this.tokenUnder(event)
    token ? this.openTokenMenu(token) : this.closeTokenMenu()
  }

  // With the pointer capture of the board, the events reach the board itself: the token is the one under the pointer
  tokenUnder(event) {
    return document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-board-token-id]")
  }

  pressToken(event) {
    if (this.tokenDrag) return this.cancelTokenDrag()
    if (event.button !== 0 || this.creature || this.mapTarget.closest("[data-moving-map]")) return

    const token = this.tokenData(this.tokenUnder(event)?.dataset.boardTokenId)
    if (!token || !this.mayMove(token)) return

    event.preventDefault()
    this.tokenDrag = { token, pointerId: event.pointerId, pressedAt: [event.clientX, event.clientY], started: false,
                       start: [token.column, token.row], cell: [token.column, token.row],
                       passage: this.passageForMoves() }
  }

  dragToken(event) {
    const drag = this.tokenDrag
    if (!drag || event.pointerId !== drag.pointerId) return
    if (!drag.started && !this.movedFrom(drag.pressedAt, event)) return

    if (!drag.started) this.closeTokenMenu()
    drag.started = true
    drag.cell = walkTowards(drag.cell, this.cellInsideTheGrid(event), drag.passage)
    this.showDraggedToken(drag)
    this.showDistance(this.distanceTo(drag), event)
  }

  // The cheapest way from the start, as the server counts it, never the whole way of the pointer
  distanceTo(drag) {
    if (drag.distanceCell && sameCell(drag.distanceCell, drag.cell)) return drag.distance

    drag.distanceCell = drag.cell
    drag.distance = pathCost(drag.start, drag.cell, drag.passage, this.gridSize()) ?? 0
    return drag.distance
  }

  dropToken(event) {
    const drag = this.tokenDrag
    if (!drag || event.pointerId !== drag.pointerId) return

    this.endTokenDrag()
    if (!drag.started) return

    if (sameCell(drag.cell, drag.start) || this.cellHoldsAnotherToken(drag.cell, drag.token.id)) return this.drawTokens()

    const [column, row] = drag.cell
    this.sendTokenRequest(`${this.tokensUrlValue}/${drag.token.id}/move`, "PATCH", { column, row })
  }

  cancelTokenDrag() {
    if (!this.tokenDrag) return

    this.endTokenDrag()
    this.drawTokens()
  }

  endTokenDrag() {
    this.tokenDrag = null
    if (this.hasMoveBubbleTarget) this.moveBubbleTarget.hidden = true
    this.mapTarget.querySelector("[data-drag-ghost]")?.remove()
  }

  tokenData(tokenId) {
    return tokenId && this.tokensOfTheMap().find((token) => String(token.id) === tokenId)
  }

  // The game master moves every token; a player the tokens of their character and of its companions
  mayMove(token) {
    if (this.gameMasterValue) return true

    const ownTokens = this.tokensTargets.find((element) => element.dataset.movableCharacterIds)
    return JSON.parse(ownTokens?.dataset.movableCharacterIds ?? "[]").includes(token.character_id)
  }

  // The game master passes everywhere; a player stops at a wall and before a blocked cell (MapPassage)
  passageForMoves() {
    if (this.gameMasterValue) return null

    const { blockedCells, blockedSides } = this.mapTarget.dataset
    return passageOf(JSON.parse(blockedCells ?? "[]"), JSON.parse(blockedSides ?? "[]"))
  }

  movedFrom([pressedX, pressedY], event) {
    return Math.hypot(event.clientX - pressedX, event.clientY - pressedY) > clickMovementTolerance
  }

  cellInsideTheGrid(event) {
    const [column, row] = this.cellAt(event)
    const [columns, rows] = this.gridSize()
    return [Math.min(Math.max(column, 0), columns - 1), Math.min(Math.max(row, 0), rows - 1)]
  }

  gridSize() {
    const { mapPreviewColumnsValue: columns, mapPreviewRowsValue: rows } = this.mapTarget.dataset
    return [Number(columns), Number(rows)]
  }

  showDraggedToken(drag) {
    const tokenGroup = this.mapTarget.querySelector(`[data-board-token-id="${drag.token.id}"]`)
    if (!tokenGroup) return

    this.leaveGhostAtStart(tokenGroup)
    const [column, row] = drag.cell
    tokenGroup.setAttribute("transform", `translate(${(column - drag.token.column) * CELL_SIZE} ${(row - drag.token.row) * CELL_SIZE})`)
    tokenGroup.parentElement.appendChild(tokenGroup)
  }

  // A faded copy of the token on its starting cell, for the one who drags it only; it takes no pointer and no id, so
  // nothing picks it. Put back after the tokens are drawn again, taken away with the drag (endTokenDrag)
  leaveGhostAtStart(tokenGroup) {
    if (this.mapTarget.querySelector("[data-drag-ghost]")) return

    const ghost = tokenGroup.cloneNode(true)
    ghost.removeAttribute("data-board-token-id")
    ghost.removeAttribute("transform")
    ghost.setAttribute("data-drag-ghost", "")
    ghost.setAttribute("opacity", ghostOpacity)
    ghost.setAttribute("pointer-events", "none")
    giveOwnClipIds(ghost)
    tokenGroup.before(ghost)
  }

  showDistance(cells, event) {
    const room = this.element.getBoundingClientRect()
    this.moveBubbleTarget.textContent = this.distanceText(cells)
    this.moveBubbleTarget.style.left = `${event.clientX - room.left + 16}px`
    this.moveBubbleTarget.style.top = `${event.clientY - room.top - 36}px`
    this.moveBubbleTarget.hidden = false
  }

  // In the distance of the template (« 7,5 m »); in cells when it gives none
  distanceText(cells) {
    const language = document.documentElement.lang || "en"
    if (this.cellLengthValue > 0) {
      const distance = new Intl.NumberFormat(language, { maximumFractionDigits: 1 }).format(cells * this.cellLengthValue)
      return this.distanceLabelValue.replace("__DISTANCE__", distance)
    }
    const form = new Intl.PluralRules(language).select(cells)
    return (this.cellsLabelsValue[form] ?? this.cellsLabelsValue.other).replace("__COUNT__", cells)
  }

  cellHoldsAnotherToken([column, row], tokenId) {
    return this.tokensOfTheMap().some((token) => token.id !== tokenId && token.column === column && token.row === row)
  }

  pointerMovedSinceDown(event) {
    if (!this.pointerDownAt) return false

    const [downX, downY] = this.pointerDownAt
    return Math.hypot(event.clientX - downX, event.clientY - downY) > clickMovementTolerance
  }

  placeCreature(event) {
    const [column, row] = this.cellAt(event)
    if (column < 0 || row < 0 || this.cellTaken(column, row) || this.cellBlocked(column, row)) return

    this.sendTokenRequest(this.tokensUrlValue, "POST", { character_id: this.creature.id, column, row })
    if (!event.shiftKey || this.creature.kind === "pc") this.dropCreature()
  }

  cellBlocked(column, row) {
    const blockedCells = JSON.parse(this.tokensTarget.dataset.blockedCells ?? "[]")
    return blockedCells.some(([blockedColumn, blockedRow]) => blockedColumn === column && blockedRow === row)
  }

  cellTaken(column, row) {
    return JSON.parse(this.tokensTarget.dataset.tokens).some((token) => token.column === column && token.row === row)
  }

  cellAt(event) {
    const point = new DOMPoint(event.clientX, event.clientY).matrixTransform(this.mapTarget.getScreenCTM().inverse())
    return [Math.floor(point.x / CELL_SIZE), Math.floor(point.y / CELL_SIZE)]
  }

  openTokenMenu(token) {
    this.menuToken = { id: token.dataset.boardTokenId, hidden: token.dataset.hidden === "true",
                       customName: token.dataset.customName, characterName: token.dataset.characterName }
    this.tokenMenuTitleTarget.textContent = token.dataset.name
    this.tokenRenameFormTarget.hidden = true
    this.tokenRenameButtonTarget.hidden = token.dataset.kind === "pc"
    this.tokenVisibilityButtonTarget.textContent = this.menuToken.hidden ? this.showLabelValue : this.hideLabelValue
    this.placeTokenMenuBeside(token)
    this.tokenMenuTarget.hidden = false
    this.tokenVisibilityButtonTarget.focus({ focusVisible: false })
  }

  placeTokenMenuBeside(token) {
    const room = this.element.getBoundingClientRect()
    const tokenBox = token.getBoundingClientRect()
    const menuWidth = this.tokenMenuTarget.offsetWidth || 224
    const fitsOnTheRight = tokenBox.right + menuGap + menuWidth < room.right
    const left = fitsOnTheRight ? tokenBox.right + menuGap : tokenBox.left - menuGap - menuWidth
    this.tokenMenuTarget.style.left = `${left - room.left}px`
    this.tokenMenuTarget.style.top = `${tokenBox.top - room.top}px`
  }

  closeTokenMenu() {
    this.menuToken = null
    if (this.hasTokenMenuTarget) this.tokenMenuTarget.hidden = true
  }

  toggleTokenVisibility() {
    if (!this.menuToken) return

    this.sendTokenRequest(this.tokenUrl(), "PATCH", { hidden: !this.menuToken.hidden })
  }

  removeToken() {
    if (!this.menuToken) return

    this.sendTokenRequest(this.tokenUrl(), "DELETE")
  }

  openTokenRename() {
    if (!this.menuToken) return

    this.tokenNameInputTarget.value = this.menuToken.customName
    this.tokenNameInputTarget.placeholder = this.menuToken.characterName
    this.tokenRenameFormTarget.hidden = false
    this.tokenNameInputTarget.focus()
    this.tokenNameInputTarget.select()
  }

  renameToken(event) {
    event.preventDefault()
    if (!this.menuToken) return

    this.sendTokenRequest(this.tokenUrl(), "PATCH", { name: this.tokenNameInputTarget.value })
  }

  tokenUrl() {
    return `${this.tokensUrlValue}/${this.menuToken.id}`
  }

  async sendTokenRequest(url, method, fields = {}) {
    const body = new FormData()
    Object.entries(fields).forEach(([name, value]) => body.append(name, value))
    const response = await fetch(url, { method, body, headers: turboStreamHeaders() }).catch(() => null)
    if (!response?.ok) return this.drawTokens()

    Turbo.renderStreamMessage(await response.text())
  }
}

// A copy of a token keeps the clip of its picture: its own id, an id being unique in the page
function giveOwnClipIds(copy) {
  copy.querySelectorAll("clipPath").forEach((clip) => {
    const ownId = `${clip.id}-ghost`
    copy.querySelectorAll(`[clip-path="url(#${clip.id})"]`).forEach((clipped) => {
      clipped.setAttribute("clip-path", `url(#${ownId})`)
    })
    clip.id = ownId
  })
}

function turboStreamHeaders() {
  return { Accept: "text/vnd.turbo-stream.html",
           "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content ?? "" }
}
