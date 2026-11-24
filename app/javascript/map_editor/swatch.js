// The small square that shows a tool of the editor (a wall, an object) beside its name, 32 units wide. A floor shows
// a piece of itself instead (map_editor/floor_sample.js)
import { paper } from "map_editor/palette"
import { createSvgElement } from "map_editor/svg"

export function drawSwatchTile(svg, fill = paper) {
  createSvgElement("rect", { x: 3, y: 3, width: 26, height: 26, fill, stroke: "#c4bcb0", "stroke-width": 0.6 }, svg)
}

export const verticalSide = { start: [16, 4], end: [16, 28], normalX: 1, normalY: 0 }
