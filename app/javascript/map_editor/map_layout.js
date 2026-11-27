// The drawing of a map while it is edited: its floors ("column,row" → floor key), its edges ("cell|cell" → edge key)
// and its objects ({ key, column, row, rotation }), and what a stroke of the editor may change. Also how the map is
// made (mode: "draw", or "picture" for a picture of one's own) and how its picture sits under the grid (picture:
// { cells_wide, offset_x, offset_y, opacity }). On a map of a table, the cells painted with the brush « Zones
// bloquantes » (blocked: no token stands on them, MapPassage) and the tokens of its non-player characters and enemies
// ({ character_id, column, row }, where the game begins). Sent to the server as the layout that MapLayoutValidator
// checks
import { cellKey, cellPosition, cellSize, sideKey } from "map_editor/square_grid"
import { doorKey } from "map_edges"
import { objectOf, footprintSize } from "map_objects"

export const layoutVersion = 1
// How close to a side the pointer must be for the eraser to take its wall rather than the floor of the cell
const eraserReach = 5

export default class MapLayout {
  constructor({ floors = {}, edges = {}, objects = [], mode = "draw", picture = null, blocked = [], tokens = [] } = {},
              grid) {
    this.grid = grid
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
    this.objects = objects.map((placedObject) => ({ ...placedObject }))
    this.mode = mode
    this.picture = picture && { ...picture }
    this.blocked = new Set(blocked)
    this.tokens = tokens.map((token) => ({ ...token }))
  }

  // The blocked cells and the tokens only once there are some: a map of « Mes cartes » never has any
  toJSON() {
    const drawing = { version: layoutVersion, floors: Object.fromEntries(this.floors),
                      edges: Object.fromEntries(this.edges), objects: this.objects, mode: this.mode }
    if (this.picture) drawing.picture = this.picture
    if (this.blocked.size > 0) drawing.blocked = [...this.blocked]
    if (this.tokens.length > 0) drawing.tokens = this.tokens
    return drawing
  }

  isPicture() {
    return this.mode === "picture"
  }

  // A copy of the drawing as it is, with the size of its grid, to come back to it (undo, redo)
  snapshot() {
    return JSON.stringify({ layout: this.toJSON(), columns: this.grid.columns, rows: this.grid.rows })
  }

  // Gives back the size of the grid of the copy: the editor makes its grid again when it changed
  restore(snapshot) {
    const { layout: { floors, edges, objects, mode = "draw", picture = null, blocked = [], tokens = [] }, columns, rows } =
      JSON.parse(snapshot)
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
    this.objects = objects
    this.mode = mode
    this.picture = picture
    this.blocked = new Set(blocked)
    this.tokens = tokens
    return { columns, rows }
  }

  // Whether something drawn would go out of a grid of that size, once moved by [columns, rows] (shiftFor)
  hasSomethingOutside(columns, rows, [columnShift, rowShift] = [0, 0]) {
    const isOutside = ([column, row]) => {
      const [newColumn, newRow] = [column + columnShift, row + rowShift]
      return newColumn < 0 || newRow < 0 || newColumn >= columns || newRow >= rows
    }
    return [...this.floors.keys()].some((key) => isOutside(cellPosition(key))) ||
      [...this.edges.keys()].some((key) => key.split("|").some((cell) => isOutside(cellPosition(cell)))) ||
      this.objects.some((placedObject) => this.cellsOf(placedObject).some(isOutside)) ||
      [...this.blocked].some((key) => isOutside(cellPosition(key))) ||
      this.tokens.some((token) => isOutside([token.column, token.row]))
  }

  // How far the drawing moves when the grid takes that size, so that it stays in the middle (Anthony's request: the
  // grid grows, or shrinks, on every side): half the columns and rows gained, or lost
  shiftFor(columns, rows) {
    return [centeringShift(this.grid.columns, columns), centeringShift(this.grid.rows, rows)]
  }

  // Everything drawn moved by whole cells: floors, walls and doors, objects, and the picture with them
  moveBy([columnShift, rowShift]) {
    if (!columnShift && !rowShift) return

    const moved = (key) => {
      const [column, row] = cellPosition(key)
      return [column + columnShift, row + rowShift]
    }
    this.floors = new Map([...this.floors].map(([key, floorKey]) => [cellKey(...moved(key)), floorKey]))
    this.edges = new Map([...this.edges].map(([key, edgeKey]) => [sideKey(...key.split("|").map(moved)), edgeKey]))
    this.objects = this.objects.map((placedObject) => ({ ...placedObject, column: placedObject.column + columnShift,
                                                          row: placedObject.row + rowShift }))
    this.blocked = new Set([...this.blocked].map((key) => cellKey(...moved(key))))
    this.tokens = this.tokens.map((token) => ({ ...token, column: token.column + columnShift, row: token.row + rowShift }))
    if (this.picture) {
      this.picture = { ...this.picture, offset_x: this.picture.offset_x + columnShift * cellSize,
                       offset_y: this.picture.offset_y + rowShift * cellSize }
    }
  }

  // What goes out of the new grid is taken out: floors, walls and doors, objects that do not hold in it whole
  cropTo(grid) {
    const isOutside = ([column, row]) => !grid.inside(column, row)
    this.floors = new Map([...this.floors].filter(([key]) => !isOutside(cellPosition(key))))
    this.edges = new Map([...this.edges].filter(([key]) => !key.split("|").some((cell) => isOutside(cellPosition(cell)))))
    this.objects = this.objects.filter((placedObject) => !this.cellsOf(placedObject).some(isOutside))
    this.blocked = new Set([...this.blocked].filter((key) => !isOutside(cellPosition(key))))
    this.tokens = this.tokens.filter((token) => !isOutside([token.column, token.row]))
    this.grid = grid
  }

  isEmpty() {
    return this.floors.size === 0 && this.edges.size === 0 && this.objects.length === 0 && this.blocked.size === 0 &&
      this.tokens.length === 0
  }

  clear() {
    this.floors.clear()
    this.edges.clear()
    this.objects = []
    this.blocked.clear()
    this.tokens = []
  }

  tokenAt(column, row) {
    return this.tokens.find((token) => token.column === column && token.row === row)
  }

  // Free, not painted blocked and, on a drawn map, on a floor (Anthony's request: never where a token cannot stand)
  mayHoldToken(column, row) {
    if (!this.grid.inside(column, row) || this.tokenAt(column, row) || this.isBlocked(column, row)) return false

    return this.isPicture() || this.floors.has(cellKey(column, row))
  }

  // One token a cell; the same character as many times as wanted (a band). true when it was put
  placeToken(characterId, column, row) {
    if (!this.mayHoldToken(column, row)) return false

    this.tokens.push({ character_id: characterId, column, row })
    return true
  }

  tokenStartsHidden(column, row) {
    return this.tokenAt(column, row)?.hidden !== false
  }

  startTokenHidden(column, row, hidden) {
    const token = this.tokenAt(column, row)
    if (!token || this.tokenStartsHidden(column, row) === hidden) return false

    token.hidden = hidden
    return true
  }

  removeTokenAt(column, row) {
    const token = this.tokenAt(column, row)
    if (!token) return false

    this.tokens = this.tokens.filter((candidate) => candidate !== token)
    return true
  }

  isBlocked(column, row) {
    return this.blocked.has(cellKey(column, row))
  }

  // true when the cell changed. Not under a token: it would stand where no token stands
  block(column, row) {
    if (this.isBlocked(column, row) || this.tokenAt(column, row)) return false

    this.blocked.add(cellKey(column, row))
    return true
  }

  unblock(column, row) {
    return this.blocked.delete(cellKey(column, row))
  }

  // true when the cell changed
  paintFloor(column, row, floorKey) {
    const key = cellKey(column, row)
    if (this.floors.get(key) === floorKey) return false

    this.floors.set(key, floorKey)
    return true
  }

  // A wall stands between two floors; a door also between a floor and the empty ground (the way in)
  mayHoldEdge(side, edgeKey) {
    const firstHasFloor = this.floors.has(cellKey(side.column, side.row))
    const secondHasFloor = this.floors.has(cellKey(side.neighbourColumn, side.neighbourRow))
    if (firstHasFloor && secondHasFloor) return true

    return edgeKey === doorKey && firstHasFloor !== secondHasFloor
  }

  hasEdge(side, edgeKey) {
    return this.edges.get(keyOfSide(side)) === edgeKey
  }

  putEdge(side, edgeKey) {
    if (this.hasEdge(side, edgeKey)) return false

    this.edges.set(keyOfSide(side), edgeKey)
    return true
  }

  removeEdge(side) {
    return this.edges.delete(keyOfSide(side))
  }

  // A token on the cell first, then an object, then the wall of a side close to the pointer, then the floor. true when
  // something went
  erase(side) {
    if (this.removeTokenAt(side.column, side.row)) return true
    if (this.removeObjectAt(side.column, side.row)) return true
    if (side.distance < eraserReach && this.removeEdge(side)) return true

    return this.floors.delete(cellKey(side.column, side.row))
  }

  // The cells of an object once turned: [[column, row], ...]
  cellsOf({ key, column, row, rotation }) {
    const [columns, rows] = footprintSize(objectOf(key), rotation)
    const cells = []
    for (let columnOffset = 0; columnOffset < columns; columnOffset++) {
      for (let rowOffset = 0; rowOffset < rows; rowOffset++) cells.push([column + columnOffset, row + rowOffset])
    }
    return cells
  }

  objectAt(column, row) {
    return this.objects.find((placedObject) => this.cellsOf(placedObject).some(([cellColumn, cellRow]) => (
      cellColumn === column && cellRow === row
    )))
  }

  // Every cell inside the grid, on a floor, free (an object being turned does not stand in its own way)
  mayPlace(placedObject, ignoredObject = null) {
    return this.cellsOf(placedObject).every(([column, row]) => {
      const objectThere = this.objectAt(column, row)
      return this.grid.inside(column, row) && this.floors.has(cellKey(column, row)) &&
        (!objectThere || objectThere === ignoredObject)
    })
  }

  placeObject(placedObject) {
    if (!this.mayPlace(placedObject)) return false

    this.objects.push(placedObject)
    return true
  }

  removeObjectAt(column, row) {
    const placedObject = this.objectAt(column, row)
    if (!placedObject) return false

    this.objects = this.objects.filter((candidate) => candidate !== placedObject)
    return true
  }

  // The next quarter turn that fits, like the prototype; nothing when none does
  turnObjectAt(column, row) {
    const placedObject = this.objectAt(column, row)
    if (!placedObject) return false

    for (let turn = 1; turn <= 3; turn++) {
      const turned = { ...placedObject, rotation: (placedObject.rotation + turn) % 4 }
      if (!this.mayPlace(turned, placedObject)) continue

      placedObject.rotation = turned.rotation
      return true
    }
    return false
  }
}

function keyOfSide({ column, row, neighbourColumn, neighbourRow }) {
  return sideKey([column, row], [neighbourColumn, neighbourRow])
}

// The cells added before the drawing (or taken away before it, negative) when a side of the grid goes from one size to
// another: half of them. An odd one goes before the drawing from an even size, after it from an odd one, so that the
// grid grown or shrunk one cell at a time (« + », « − ») alternates its sides, and comes back the same
function centeringShift(oldSize, newSize) {
  const change = newSize - oldSize
  if (change >= 0) return Math.floor((change + (oldSize % 2 === 0 ? 1 : 0)) / 2)

  return -Math.floor((-change + (oldSize % 2 === 1 ? 1 : 0)) / 2)
}
