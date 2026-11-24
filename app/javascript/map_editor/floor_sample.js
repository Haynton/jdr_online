// The swatch of a floor in the panel of the editor (Anthony's request: prettier ones): a little piece of that floor,
// drawn by the renderer of the map itself, so that it shows what the floor really looks like, its edges included (the
// ink wall and the hatching of a room, the stone walls, the low wall of an enclosure, the bank of water, the rocks
// outside, the soft edge of open air). A corner of a floor of three cells by three, framed on its top left corner: mostly
// the floor, its edge on two sides, without the lines of the grid
import SquareGrid, { cellKey, cellSize } from "map_editor/square_grid"
import { renderMap } from "map_editor/map_renderer"
import { createSvgElement } from "map_editor/svg"
import { voidGround } from "map_editor/palette"

const sampleGrid = new SquareGrid(5, 5)
const sampleCells = [1, 2, 3].flatMap((column) => [1, 2, 3].map((row) => [column, row]))
// From a little before the corner, so that its edge shows, over two cells of the floor
const frameStart = cellSize * 0.6
const frameSize = cellSize * 2.2

export function drawFloorSample(svg, floorKey) {
  svg.setAttribute("viewBox", `${frameStart} ${frameStart} ${frameSize} ${frameSize}`)
  svg.style.backgroundColor = voidGround
  const floors = new Map(sampleCells.map(([column, row]) => [cellKey(column, row), floorKey]))
  renderMap(createSvgElement("g", {}, svg), { grid: sampleGrid, floors, edges: new Map(), objects: [], showGrid: false })
}
