// The part of the map the board shows (its viewBox): the whole map at first, then zoomed in around a point and moved.
// Never further out than the whole map, never moved past its edges (decision): on a side where the whole map does
// not fill the board, it stays in the middle. The view keeps the proportions of the board, so that a cell stays square
// The whole map touches the edges of the board, like the prototype: the ground fills what is left
const marginInCells = 0
const smallestZoom = 1
const largestZoom = 8

export default class BoardView {
  constructor(grid, cellSize) {
    this.grid = grid
    this.margin = marginInCells * cellSize
    this.zoom = 1
    this.centerX = grid.width / 2
    this.centerY = grid.height / 2
  }

  // The board has a new size (first display, window resized): the same zoom and the same center
  resize(boardWidth, boardHeight) {
    this.boardWidth = boardWidth
    this.boardHeight = boardHeight
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
    const fittingUnitsPerPixel = Math.max((this.grid.width + this.margin * 2) / this.boardWidth,
                                          (this.grid.height + this.margin * 2) / this.boardHeight)
    return fittingUnitsPerPixel / this.zoom
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
    this.centerX = centerWithin(this.centerX, this.boardWidth * this.unitsPerPixel(), this.grid.width)
    this.centerY = centerWithin(this.centerY, this.boardHeight * this.unitsPerPixel(), this.grid.height)
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

// The center of a view of that size, so that the view stays on the map; in the middle when the view is larger
function centerWithin(center, viewSize, mapSize) {
  if (viewSize >= mapSize) return mapSize / 2

  return Math.min(mapSize - viewSize / 2, Math.max(viewSize / 2, center))
}
