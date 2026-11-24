// MapEdges::StoneWall: a wall of stones. It joins the outline of a paved floor (map_floors/stone), cut on a miter
import { drawStoneWall, stoneWallThickness } from "map_editor/wall_drawing"
import { drawSwatchTile, verticalSide } from "map_editor/swatch"

export default {
  key: "stone_wall",
  joinsOutline: true,
  thickness: stoneWallThickness,
  castsShadow: true,
  draw(group, side, { seed, startEnd, endEnd }) {
    drawStoneWall(group, side, seed, startEnd, endEnd)
  },
  drawSegment: drawStoneWall,
  drawSwatch(svg) {
    drawSwatchTile(svg)
    drawStoneWall(svg, verticalSide, 7)
  }
}
