// The grid of square cells of a map: where a cell is drawn, its neighbours, the side between two of them. A cell is
// written "column,row" (cellKey), a side "cellKey|cellKey", the two cells in sorted order, as MapLayoutValidator
// checks them
export const cellSize = 24

export function cellKey(column, row) {
  return `${column},${row}`
}

export function cellPosition(key) {
  return key.split(",").map(Number)
}

export function sideKey(firstCell, secondCell) {
  return [cellKey(...firstCell), cellKey(...secondCell)].sort().join("|")
}

export default class SquareGrid {
  constructor(columns, rows) {
    this.columns = columns
    this.rows = rows
    this.width = columns * cellSize
    this.height = rows * cellSize
  }

  inside(column, row) {
    return column >= 0 && row >= 0 && column < this.columns && row < this.rows
  }

  center(column, row) {
    return [column * cellSize + cellSize / 2, row * cellSize + cellSize / 2]
  }

  // Top left, top right, bottom right, bottom left: the side n runs from the corner n to the next one
  corners(column, row) {
    const left = column * cellSize
    const top = row * cellSize
    return [[left, top], [left + cellSize, top], [left + cellSize, top + cellSize], [left, top + cellSize]]
  }

  // Above, right, below, left: the neighbour n is across the side n
  neighbours(column, row) {
    return [[column, row - 1], [column + 1, row], [column, row + 1], [column - 1, row]]
  }

  cellAt(x, y) {
    return [Math.floor(x / cellSize), Math.floor(y / cellSize)]
  }

  // The side n of a cell: its two ends, and the normal that points out of the cell
  side(column, row, sideIndex) {
    const corners = this.corners(column, row)
    const start = corners[sideIndex]
    const end = corners[(sideIndex + 1) % corners.length]
    const [centerX, centerY] = this.center(column, row)
    const middle = [(start[0] + end[0]) / 2, (start[1] + end[1]) / 2]
    const length = Math.hypot(middle[0] - centerX, middle[1] - centerY)
    return { start, end, normalX: (middle[0] - centerX) / length, normalY: (middle[1] - centerY) / length }
  }

  // The side of the cell under the point that the point is closest to, and how far it is
  nearestSide([x, y]) {
    const [column, row] = this.cellAt(x, y)
    return this.neighbours(column, row).map(([neighbourColumn, neighbourRow], sideIndex) => {
      const { start, end } = this.side(column, row, sideIndex)
      return { column, row, neighbourColumn, neighbourRow, sideIndex,
               distance: distanceToSegment([x, y], start, end) }
    }).reduce((closest, side) => (side.distance < closest.distance ? side : closest))
  }
}

export function distanceToSegment([x, y], start, end) {
  const alongX = end[0] - start[0]
  const alongY = end[1] - start[1]
  const progress = ((x - start[0]) * alongX + (y - start[1]) * alongY) / (alongX * alongX + alongY * alongY)
  const clamped = Math.max(0, Math.min(1, progress))
  return Math.hypot(x - start[0] - alongX * clamped, y - start[1] - alongY * clamped)
}
