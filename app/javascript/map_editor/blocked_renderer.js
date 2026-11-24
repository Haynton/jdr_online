// The cells painted with the brush « Zones bloquantes » (a map of a table: no token stands on them, MapPassage), drawn
// over the map in the editor only: a red veil, hatched, so that they show on any floor and on any picture
import { cellSize, cellPosition } from "map_editor/square_grid"
import { createSvgElement } from "map_editor/svg"
import { refusedMark } from "map_editor/palette"

// Three lines across a cell
const hatchingCount = 3

export function renderBlockedCells(group, blockedCells) {
  if (blockedCells.size === 0) return

  let veil = ""
  let hatching = ""
  blockedCells.forEach((key) => {
    const [column, row] = cellPosition(key)
    const [left, top] = [column * cellSize, row * cellSize]
    veil += `M${left} ${top} h${cellSize} v${cellSize} h${-cellSize} Z `
    hatching += cellHatching(left, top)
  })
  const layer = createSvgElement("g", { "pointer-events": "none" }, group)
  createSvgElement("path", { d: veil, fill: refusedMark, "fill-opacity": 0.22, stroke: refusedMark,
                             "stroke-width": 1, "stroke-opacity": 0.6 }, layer)
  createSvgElement("path", { d: hatching, fill: "none", stroke: refusedMark, "stroke-width": 1.2,
                             "stroke-opacity": 0.55, "stroke-linecap": "round" }, layer)
}

// Lines from the bottom left to the top right, each one inside the cell
function cellHatching(left, top) {
  const step = (cellSize * 2) / (hatchingCount + 1)
  let path = ""
  for (let line = 1; line <= hatchingCount; line++) {
    const reach = step * line
    const start = [left + Math.max(0, reach - cellSize), top + Math.min(cellSize, reach)]
    const end = [left + Math.min(cellSize, reach), top + Math.max(0, reach - cellSize)]
    path += `M${start[0]} ${start[1]} L${end[0]} ${end[1]} `
  }
  return path
}
