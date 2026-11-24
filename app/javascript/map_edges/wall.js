// MapEdges::Wall: a wall drawn in ink, between two cells
import { drawInkWall } from "map_editor/wall_drawing"
import { drawSwatchTile, verticalSide } from "map_editor/swatch"

export default {
  key: "wall",
  joinsOutline: false,
  thickness: 0,
  castsShadow: true,
  draw(group, side) {
    drawInkWall(group, side.start, side.end, 2.6)
  },
  drawSwatch(svg) {
    drawSwatchTile(svg)
    drawInkWall(svg, verticalSide.start, verticalSide.end, 3.2)
  }
}
