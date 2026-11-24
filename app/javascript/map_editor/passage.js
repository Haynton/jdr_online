// What stops a token by itself on a drawn map, the twin of MapPassage (app/models/map_passage.rb), shown in the editor
// while the game master paints the blocked zones (Anthony's request: to see what blocks already). Changing one means
// changing the other. The empty ground, and the walls a room or stones draw by themselves (read from the twins of the
// floors, like map_renderer.js draws them): towards open air, a floor walls itself unless it is open air or water;
// between two other floors, the stone wall of a paving stops, where only one of them is paved. A door put in such a
// wall is a way through. A map played on a picture blocks nothing by itself
import { floorOf, isAir } from "map_floors"
import { doorKey } from "map_edges"
import { cellKey, cellPosition, sideKey } from "map_editor/square_grid"

const stoneWallKey = "stone_wall"

// { emptyCells: [[column, row], ...], sides: [{ column, row, sideIndex }, ...] }, each side seen once
export function naturalBlocks({ grid, floors, edges }) {
  const emptyCells = []
  for (let column = 0; column < grid.columns; column++) {
    for (let row = 0; row < grid.rows; row++) {
      if (!floorOf(floors.get(cellKey(column, row)))) emptyCells.push([column, row])
    }
  }
  return { emptyCells, sides: blockedSides(grid, floors, edges) }
}

function blockedSides(grid, floors, edges) {
  const sides = []
  const seen = new Set()
  floors.forEach((floorKey, key) => {
    const floor = floorOf(floorKey)
    const [column, row] = cellPosition(key)
    if (!floor || !grid.inside(column, row)) return

    grid.neighbours(column, row).forEach(([neighbourColumn, neighbourRow], sideIndex) => {
      const neighbour = floorOf(floors.get(cellKey(neighbourColumn, neighbourRow)))
      const side = sideKey([column, row], [neighbourColumn, neighbourRow])
      if (!neighbour || !grid.inside(neighbourColumn, neighbourRow) || seen.has(side)) return
      if (edges.get(side) === doorKey || !isWalled(floor, neighbour)) return

      seen.add(side)
      sides.push({ column, row, sideIndex })
    })
  })
  return sides
}

function isWalled(floor, neighbour) {
  if (neighbour.open && !isAir(floor)) return wallsBlock(floor)
  if (floor.open && !isAir(neighbour)) return wallsBlock(neighbour)

  return hasStoneWalls(floor) !== hasStoneWalls(neighbour)
}

// The ink wall of a room, the stone wall of a paving (MapFloors::Base#walls_block?)
function wallsBlock(floor) {
  return Boolean(floor.inkBorder) || hasStoneWalls(floor)
}

function hasStoneWalls(floor) {
  return floor.wallKey === stoneWallKey
}
