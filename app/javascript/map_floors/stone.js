// MapFloors::Stone: paving stones, walled in stone where they meet the empty ground or open air
import { drawStoneWall } from "map_editor/wall_drawing"
import { stonePattern } from "map_editor/patterns"
import { drawSwatchTile, topSide, bottomSide } from "map_editor/swatch"

export default {
  key: "stone",
  pattern: stonePattern,
  wallKey: "stone_wall",
  inkBorder: false,
  shadowsOutside: true,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null,
  drawSwatch(svg) {
    drawSwatchTile(svg, stonePattern)
    drawStoneWall(svg, topSide, 3)
    drawStoneWall(svg, bottomSide, 4)
  }
}
