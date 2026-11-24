// MapEdges::Door: a door in the wall of its side (wallStyle: the stones of a paved floor, the low wall of an
// enclosure, or ink). A door can also stand between a floor and the empty ground around it: the way in
import { drawDoor } from "map_editor/wall_drawing"
import { drawSwatchTile, verticalSide } from "map_editor/swatch"

export default {
  key: "door",
  joinsOutline: true,
  thickness: 0,
  castsShadow: false,
  draw(group, side, { seed, startEnd, endEnd, wallStyle }) {
    drawDoor(group, side, { wallStyle, seed, startEnd, endEnd })
  },
  drawSwatch(svg) {
    drawSwatchTile(svg)
    drawDoor(svg, { ...verticalSide, start: [16, 2], end: [16, 30] }, { seed: 2 })
  }
}
