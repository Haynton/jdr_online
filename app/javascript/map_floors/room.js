// MapFloors::Room: a plank floor. Where it meets the empty ground (or open air), an ink wall, hatched outside
import { drawInkWall } from "map_editor/wall_drawing"
import { woodPattern } from "map_editor/patterns"
import { drawSwatchTile, topSide, bottomSide } from "map_editor/swatch"

export default {
  key: "room",
  pattern: woodPattern,
  wallKey: null,
  inkBorder: true,
  shadowsOutside: true,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null,
  drawSwatch(svg) {
    drawSwatchTile(svg, woodPattern)
    drawInkWall(svg, topSide.start, topSide.end, 2.2)
    drawInkWall(svg, bottomSide.start, bottomSide.end, 2.2)
  }
}
