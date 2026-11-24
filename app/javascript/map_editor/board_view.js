// The part of the map the board shows (its viewBox): the whole map at first, filling the board, then zoomed in around
// a point and moved. Never further out than the whole map. The pieces floating over the board (the size of the grid,
// the zoom, what was saved) cover some of it: its insets, in pixels. The map may move past its edges by them, and no
// further (Anthony's choice: the map keeps the whole board, rather than shrinking to stay clear of them), so that any
// cell can come out from under them, zoomed in or not. The view keeps the proportions of the board, so that a cell
// stays square; the ground fills the rest
const smallestZoom = 1
const largestZoom = 8
const noInsets = { top: 0, right: 0, bottom: 0, left: 0 }

export default class BoardView {
  constructor(grid) {
    this.grid = grid
    this.insets = noInsets
    this.zoom = 1
    this.centerX = grid.width / 2
    this.centerY = grid.height / 2
  }

  // The board has a new size (first display, window resized) or its floating pieces moved: the same zoom, the same
  // center
  resize(boardWidth, boardHeight, insets = this.insets) {
    this.boardWidth = boardWidth
    this.boardHeight = boardHeight
    this.insets = insets
    this.keepInsideTheMap()
  }

  // The whole map in the board
  fitWholeMap() {
    this.zoom = 1
    this.centerX = this.grid.width / 2
    this.centerY = this.grid.height / 2
  }

  // How many units of the map one pixel of the board shows, the whole map at a zoom of 1
  unitsPerPixel() {
    return Math.max(this.grid.width / this.boardWidth, this.grid.height / this.boardHeight) / this.zoom
  }

  // factor above 1 zooms in. The point of the map under [x, y] stays under the pointer
  zoomAround([x, y], factor) {
    const newZoom = Math.min(largestZoom, Math.max(smallestZoom, this.zoom * factor))
    const appliedFactor = newZoom / this.zoom
    this.centerX = x + (this.centerX - x) / appliedFactor
    this.centerY = y + (this.centerY - y) / appliedFactor
    this.zoom = newZoom
    this.keepInsideTheMap()
  }

  // Moved by pixels of the board: the map follows the pointer
  moveByPixels(pixelsX, pixelsY) {
    this.centerX -= pixelsX * this.unitsPerPixel()
    this.centerY -= pixelsY * this.unitsPerPixel()
    this.keepInsideTheMap()
  }

  // Also after a resize of the board
  keepInsideTheMap() {
    const unitsPerPixel = this.unitsPerPixel()
    this.centerX = centerWithin(this.centerX, this.boardWidth * unitsPerPixel, this.grid.width,
                                this.insets.left * unitsPerPixel, this.insets.right * unitsPerPixel)
    this.centerY = centerWithin(this.centerY, this.boardHeight * unitsPerPixel, this.grid.height,
                                this.insets.top * unitsPerPixel, this.insets.bottom * unitsPerPixel)
  }

  // The point of the map under a pixel of the board, counted from its top left corner: the view keeps the
  // proportions of the board, so one scale serves both directions
  pointAt(pixelX, pixelY) {
    const unitsPerPixel = this.unitsPerPixel()
    const left = this.centerX - (this.boardWidth * unitsPerPixel) / 2
    const top = this.centerY - (this.boardHeight * unitsPerPixel) / 2
    return [left + pixelX * unitsPerPixel, top + pixelY * unitsPerPixel]
  }

  viewBox() {
    const width = this.boardWidth * this.unitsPerPixel()
    const height = this.boardHeight * this.unitsPerPixel()
    return `${this.centerX - width / 2} ${this.centerY - height / 2} ${width} ${height}`
  }

  zoomPercent() {
    return Math.round(this.zoom * 100)
  }
}

// The center of a view of that size on one side of the map: the view stays on the map, in the middle when it is
// larger, and may go past its edges by what covers them at the start (before) and at the end (after) of the board
function centerWithin(center, viewSize, mapSize, before, after) {
  const lowest = Math.min(viewSize / 2, mapSize / 2) - before
  const highest = Math.max(mapSize - viewSize / 2, mapSize / 2) + after
  return Math.min(highest, Math.max(lowest, center))
}
