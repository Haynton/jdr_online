// The small square that shows a tool of the editor (a floor, a wall) beside its name, 32 units wide
import { paper } from "map_editor/palette"
import { createSvgElement } from "map_editor/svg"

export function drawSwatchTile(svg, fill = paper) {
  createSvgElement("rect", { x: 3, y: 3, width: 26, height: 26, fill, stroke: "#c4bcb0", "stroke-width": 0.6 }, svg)
}

export const verticalSide = { start: [16, 4], end: [16, 28], normalX: 1, normalY: 0 }
export const topSide = { start: [4, 9], end: [28, 9], normalX: 0, normalY: -1 }
export const bottomSide = { start: [4, 23], end: [28, 23], normalX: 0, normalY: 1 }
