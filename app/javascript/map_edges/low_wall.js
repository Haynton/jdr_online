// MapEdges::LowWall: a low wall of piled stones, the fence of an enclosure (map_floors/enclosure)
import { drawLowWall, lowWallThickness } from "map_editor/wall_drawing"
import { drawSwatchTile, verticalSide } from "map_editor/swatch"

export default {
  key: "low_wall",
  joinsOutline: true,
  thickness: lowWallThickness,
  castsShadow: true,
  draw(group, side, { seed, startEnd, endEnd }) {
    drawLowWall(group, side, seed, startEnd, endEnd)
  },
  drawSegment: drawLowWall,
  drawSwatch(svg) {
    drawSwatchTile(svg)
    drawLowWall(svg, { ...verticalSide, start: [16, 2], end: [16, 30] }, 7)
  }
}
