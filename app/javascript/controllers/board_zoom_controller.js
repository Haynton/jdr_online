import { Controller } from "@hotwired/stimulus"
import SquareGrid from "map_editor/square_grid"
import BoardView from "map_editor/board_view"
import { isTouchpadSlide, wheelPixels, pinchShape } from "map_editor/gestures"
import { isTyping } from "map_editor/typing"

const zoomStep = 1.25
const islandsReach = 88
const mainButton = 0
const middleButton = 1

export default class extends Controller {
  static targets = ["map", "zoomButtons", "handButton"]
  static values = { columns: Number, rows: Number }

  connect() {
    this.view = new BoardView(new SquareGrid(this.columnsValue, this.rowsValue))
    this.activePointers = new Map()
    this.fitToBoard()
    this.resizeObserver = new ResizeObserver(() => this.fitToBoard())
    this.resizeObserver.observe(this.mapTarget)
    this.zoomButtonsTarget.hidden = false
  }

  disconnect() {
    this.resizeObserver.disconnect()
  }

  fitToBoard() {
    const { width, height } = this.mapTarget.getBoundingClientRect()
    if (!width || !height) return

    this.view.resize(width, height, { top: islandsReach, right: islandsReach, bottom: islandsReach, left: islandsReach })
    this.showView()
  }

  showView() {
    this.mapTarget.setAttribute("viewBox", this.view.viewBox())
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

  zoomOrMoveWithWheel(event) {
    event.preventDefault()
    if (!event.ctrlKey && isTouchpadSlide(event)) {
      this.view.moveByPixels(-event.deltaX, -event.deltaY)
    } else {
      const speed = event.ctrlKey ? 0.01 : 0.0015
      this.view.zoomAround(this.mapPoint(event), Math.exp(-wheelPixels(event) * speed))
    }
    this.showView()
  }

  startGesture(event) {
    event.preventDefault()
    this.gestureScale = 1
  }

  zoomWithGesture(event) {
    event.preventDefault()
    this.view.zoomAround(this.mapPoint(event), event.scale / this.gestureScale)
    this.gestureScale = event.scale
    this.showView()
  }

  pressPointer(event) {
    this.activePointers.set(event.pointerId, [event.clientX, event.clientY])
    this.mapTarget.setPointerCapture(event.pointerId)
    if (this.activePointers.size === 2) return this.startPinch()
    if (!this.movesTheMap(event)) return

    event.preventDefault()
    this.movingFrom = [event.clientX, event.clientY]
  }

  movePointer(event) {
    if (!this.activePointers.has(event.pointerId)) return

    this.activePointers.set(event.pointerId, [event.clientX, event.clientY])
    if (this.pinch) return this.continuePinch()
    if (this.movingFrom) this.continueMoving(event)
  }

  releasePointer(event) {
    this.activePointers.delete(event.pointerId)
    if (this.activePointers.size < 2) this.pinch = null
    this.movingFrom = null
  }

  movesTheMap(event) {
    if (event.button === middleButton) return true

    return event.button === mainButton && this.element.hasAttribute("data-moving-map")
  }

  enterMap() {
    this.isPointerOverMap = true
  }

  leaveMap() {
    this.isPointerOverMap = false
  }

  holdSpace(event) {
    if (!this.isPointerOverMap || isTyping(event)) return

    event.preventDefault()
    this.isSpaceHeld = true
    this.showMovingState()
  }

  releaseSpace(event) {
    if (!this.isSpaceHeld) return

    event.preventDefault()
    this.isSpaceHeld = false
    this.showMovingState()
  }

  toggleHand() {
    this.isHandOn = !this.isHandOn
    this.showMovingState()
  }

  toggleHandWithKey(event) {
    if (isTyping(event) || event.ctrlKey || event.metaKey || event.altKey) return

    this.toggleHand()
  }

  showMovingState() {
    this.element.toggleAttribute("data-moving-map", Boolean(this.isHandOn || this.isSpaceHeld))
    this.handButtonTarget.setAttribute("aria-pressed", String(Boolean(this.isHandOn)))
  }

  continueMoving(event) {
    this.view.moveByPixels(event.clientX - this.movingFrom[0], event.clientY - this.movingFrom[1])
    this.movingFrom = [event.clientX, event.clientY]
    this.showView()
  }

  startPinch() {
    this.movingFrom = null
    this.pinch = pinchShape(this.activePointers)
  }

  continuePinch() {
    const shape = pinchShape(this.activePointers)
    this.view.zoomAround(this.mapPoint({ clientX: shape.middle[0], clientY: shape.middle[1] }),
                         shape.distance / this.pinch.distance)
    this.view.moveByPixels(shape.middle[0] - this.pinch.middle[0], shape.middle[1] - this.pinch.middle[1])
    this.pinch = shape
    this.showView()
  }

  mapPoint(event) {
    const map = this.mapTarget.getBoundingClientRect()
    return this.view.pointAt(event.clientX - map.left, event.clientY - map.top)
  }
}
