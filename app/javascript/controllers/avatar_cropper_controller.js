import { Controller } from "@hotwired/stimulus"

// Frames a picture before it is sent as an avatar (shared/_avatar_picker): the file chosen opens a window where the
// picture lies behind a frame (round for an account, square for a character). Dragging it (or the arrow keys)
// places the face, the slider enlarges it. Confirmed, what the frame holds is drawn on a canvas, shrunk to a square of
// outputSize pixels, and sent in place of the original: a few dozen kilobytes, whatever the photo. The picture always
// covers the frame (never an empty corner). Without JavaScript, the file field and its button send the photo as it is
const ARROW_MOVES = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }
const ARROW_STEP = 8
const ARROW_STEP_WITH_SHIFT = 32
const MAXIMUM_ZOOM = 4

export default class extends Controller {
  static targets = ["input", "dialog", "stage", "frame", "image", "zoom", "fallback", "status"]
  static values = { outputSize: Number, sendingLabel: String }

  // Also when a Turbo Stream puts back the body of the picker, as the server drew it
  fallbackTargetConnected(button) {
    button.hidden = true
  }

  open() {
    const [file] = this.inputTarget.files
    if (!file) return
    if (!file.type.startsWith("image/")) return this.send()

    this.forgetPicture()
    this.sending = false
    this.pictureUrl = URL.createObjectURL(file)
    this.imageTarget.onload = () => this.startFraming()
    this.imageTarget.src = this.pictureUrl
  }

  startFraming() {
    this.dialogTarget.showModal()
    this.dialogTarget.focus()
    const { naturalWidth, naturalHeight } = this.imageTarget
    this.frameSize = this.frameTarget.offsetWidth
    this.frameOffset = this.frameTarget.offsetLeft
    this.coverScale = this.frameSize / Math.min(naturalWidth, naturalHeight)
    this.zoomTarget.value = 1
    this.scale = this.coverScale
    const width = naturalWidth * this.scale
    const height = naturalHeight * this.scale
    this.moveTo(this.frameOffset + (this.frameSize - width) / 2, this.frameOffset + (this.frameSize - height) / 2)
  }

  startDragging(event) {
    if (event.button !== 0) return

    this.stageTarget.setPointerCapture(event.pointerId)
    this.dragStart = { pointerX: event.clientX, pointerY: event.clientY, left: this.left, top: this.top }
  }

  drag(event) {
    if (!this.dragStart) return

    const { pointerX, pointerY, left, top } = this.dragStart
    this.moveTo(left + event.clientX - pointerX, top + event.clientY - pointerY)
  }

  stopDragging() {
    this.dragStart = null
  }

  moveWithKeys(event) {
    const direction = ARROW_MOVES[event.key]
    if (!direction) return

    event.preventDefault()
    const step = event.shiftKey ? ARROW_STEP_WITH_SHIFT : ARROW_STEP
    this.moveTo(this.left + direction[0] * step, this.top + direction[1] * step)
  }

  zoomWithWheel(event) {
    event.preventDefault()
    const zoom = Number(this.zoomTarget.value) * (event.deltaY < 0 ? 1.1 : 1 / 1.1)
    this.zoomTarget.value = Math.min(MAXIMUM_ZOOM, Math.max(1, zoom))
    this.zoom()
  }

  // The point of the picture at the centre of the frame stays there
  zoom() {
    const centre = this.frameOffset + this.frameSize / 2
    const pictureX = (centre - this.left) / this.scale
    const pictureY = (centre - this.top) / this.scale
    this.scale = this.coverScale * Number(this.zoomTarget.value)
    this.moveTo(centre - pictureX * this.scale, centre - pictureY * this.scale)
  }

  // Never beyond the edges of the picture: it always covers the whole frame
  moveTo(left, top) {
    const width = this.imageTarget.naturalWidth * this.scale
    const height = this.imageTarget.naturalHeight * this.scale
    const frameEnd = this.frameOffset + this.frameSize
    this.left = Math.min(this.frameOffset, Math.max(frameEnd - width, left))
    this.top = Math.min(this.frameOffset, Math.max(frameEnd - height, top))
    Object.assign(this.imageTarget.style, {
      width: `${width}px`, height: `${height}px`, transform: `translate(${this.left}px, ${this.top}px)`
    })
  }

  async confirm() {
    const croppedFile = await this.croppedPicture()
    const transfer = new DataTransfer()
    transfer.items.add(croppedFile)
    this.inputTarget.files = transfer.files
    this.sending = true
    this.dialogTarget.close()
    this.send()
  }

  cancel() {
    this.dialogTarget.close()
  }

  // Closed without confirming (Cancel, Escape): the file chosen is forgotten, nothing is sent
  closed() {
    if (this.sending) return

    this.inputTarget.value = ""
    this.forgetPicture()
  }

  send() {
    if (this.hasStatusTarget) this.statusTarget.textContent = this.sendingLabelValue
    this.inputTarget.form.requestSubmit()
    this.forgetPicture()
  }

  async croppedPicture() {
    const canvas = document.createElement("canvas")
    canvas.width = this.outputSizeValue
    canvas.height = this.outputSizeValue
    const sourceSize = this.frameSize / this.scale
    const sourceX = (this.frameOffset - this.left) / this.scale
    const sourceY = (this.frameOffset - this.top) / this.scale
    canvas.getContext("2d").drawImage(this.imageTarget, sourceX, sourceY, sourceSize, sourceSize,
      0, 0, this.outputSizeValue, this.outputSizeValue)
    const blob = await this.encode(canvas)
    const extension = blob.type === "image/webp" ? "webp" : "jpg"
    return new File([blob], `avatar.${extension}`, { type: blob.type })
  }

  // Safari cannot write WebP: a browser that gives back another type writes a JPEG instead
  async encode(canvas) {
    const webp = await new Promise((resolve) => canvas.toBlob(resolve, "image/webp", 0.85))
    if (webp?.type === "image/webp") return webp

    return new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.9))
  }

  forgetPicture() {
    if (this.pictureUrl) URL.revokeObjectURL(this.pictureUrl)
    this.pictureUrl = null
  }

  disconnect() {
    this.forgetPicture()
  }
}
