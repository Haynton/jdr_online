// The drawing of a map while it is edited: its floors ("column,row" → floor key) and its edges ("cell|cell" → edge
// key), and what a stroke of the editor may change. Sent to the server as the layout that MapLayoutValidator checks
import { cellKey, sideKey } from "map_editor/square_grid"
import { doorKey } from "map_edges"

export const layoutVersion = 1
// How close to a side the pointer must be for the eraser to take its wall rather than the floor of the cell
const eraserReach = 5

export default class MapLayout {
  constructor({ floors = {}, edges = {} } = {}) {
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
  }

  toJSON() {
    return { version: layoutVersion, floors: Object.fromEntries(this.floors), edges: Object.fromEntries(this.edges) }
  }

  // A copy of the drawing as it is, to come back to it (undo, redo)
  snapshot() {
    return JSON.stringify(this.toJSON())
  }

  restore(snapshot) {
    const { floors, edges } = JSON.parse(snapshot)
    this.floors = new Map(Object.entries(floors))
    this.edges = new Map(Object.entries(edges))
  }

  isEmpty() {
    return this.floors.size === 0 && this.edges.size === 0
  }

  clear() {
    this.floors.clear()
    this.edges.clear()
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

  // Close to a side that holds a wall: the wall goes. Otherwise the floor of the cell. true when something went
  erase(side) {
    if (side.distance < eraserReach && this.removeEdge(side)) return true

    return this.floors.delete(cellKey(side.column, side.row))
  }
}

function keyOfSide({ column, row, neighbourColumn, neighbourRow }) {
  return sideKey([column, row], [neighbourColumn, neighbourRow])
}
