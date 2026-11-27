import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { createSvgElement } from "map_editor/svg"
import { renderBoardTokens } from "map_editor/token_renderer"

const CELL_SIZE = 24
const clickMovementTolerance = 5
const menuGap = 8

export default class extends Controller {
  static targets = ["map", "tokens", "creaturePlacer", "hint", "hintName", "tokenMenu", "tokenMenuTitle",
                    "tokenVisibilityButton", "tokenRenameButton", "tokenRenameForm", "tokenNameInput"]
  static values = { hint: String, tokensUrl: String, showLabel: String, hideLabel: String }

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
  }

  creaturePlacerTargetConnected(button) {
    button.hidden = false
    this.showCreaturePlacer(button)
  }

  drawTokens() {
    if (!this.hasMapTarget || !this.hasTokensTarget) return

    renderBoardTokens(this.tokensLayer(), JSON.parse(this.tokensTarget.dataset.tokens))
  }

  tokensLayer() {
    const layer = this.mapTarget.querySelector("[data-board-tokens-layer]") ||
      createSvgElement("g", { "data-board-tokens-layer": "" })
    this.mapTarget.appendChild(layer)
    return layer
  }

  showCreaturePlacer(button) {
    button.setAttribute("aria-disabled", String(!this.hasMapTarget))
    button.title = this.hasMapTarget ? button.dataset.placeLabel : button.dataset.needsMapLabel
  }

  takeCreature(event) {
    if (!this.hasMapTarget) return
    if (this.creature?.id === event.params.id) return this.dropCreature()

    this.closeTokenMenu()
    this.creature = { id: event.params.id, name: event.params.name }
    this.pressCreaturePlacer(event.currentTarget)
    this.hintNameTarget.textContent = this.hintValue.replace("__NAME__", this.creature.name)
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

    const token = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-board-token-id]")
    token ? this.openTokenMenu(token) : this.closeTokenMenu()
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
    if (!event.shiftKey) this.dropCreature()
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
    const response = await fetch(url, { method, body, headers: turboStreamHeaders() })
    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }
}

function turboStreamHeaders() {
  return { Accept: "text/vnd.turbo-stream.html",
           "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content ?? "" }
}
