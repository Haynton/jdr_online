// The drawing of a map while it is edited: its floors ("column,row" → floor key), its edges ("cell|cell" → edge key)
// and its objects ({ key, column, row, rotation }), and what a stroke of the editor may change. Sent to the server as
// the layout that MapLayoutValidator checks
import { cellKey, sideKey } from "map_editor/square_grid"
import { doorKey } from "map_edges"
import { objectOf, footprintSize } from "map_objects"

export const layoutVersion = 1
// How close to a side the pointer must be for the eraser to take its wall rather than the floor of the cell
const eraserReach = 5

export default class MapLayout {
  constructor({ floors = {}, edges = {}, objects = [] } = {}, grid) {
    this.grid = grid
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
    this.objects = objects.map((placedObject) => ({ ...placedObject }))
  }

  toJSON() {
    return { version: layoutVersion, floors: Object.fromEntries(this.floors), edges: Object.fromEntries(this.edges),
             objects: this.objects }
  }

  // A copy of the drawing as it is, to come back to it (undo, redo)
  snapshot() {
    return JSON.stringify(this.toJSON())
  }

  restore(snapshot) {
    const { floors, edges, objects } = JSON.parse(snapshot)
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
    this.objects = objects
  }

  isEmpty() {
    return this.floors.size === 0 && this.edges.size === 0 && this.objects.length === 0
  }

  clear() {
    this.floors.clear()
    this.edges.clear()
    this.objects = []
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

  // An object on the cell first, then the wall of a side close to the pointer, then the floor. true when something went
  erase(side) {
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
