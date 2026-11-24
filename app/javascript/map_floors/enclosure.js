// MapFloors::Enclosure: dirt ground, fenced by a low wall where it meets the empty ground or open air
import { drawLowWall } from "map_editor/wall_drawing"
import { dirtPattern } from "map_editor/patterns"
import { dirtSpeck } from "map_editor/palette"
import { drawSwatchTile, topSide, bottomSide } from "map_editor/swatch"

export default {
  key: "enclosure",
  pattern: dirtPattern,
  wallKey: "low_wall",
  inkBorder: false,
  shadowsOutside: true,
  pebblesOutside: () => 1,
  rocksOutside: false,
  speckles: { color: dirtSpeck, bladeChance: 0.08 },
  drawSwatch(svg) {
    drawSwatchTile(svg, dirtPattern)
    drawLowWall(svg, { ...topSide, start: [2, 10], end: [30, 10] }, 3)
    drawLowWall(svg, { ...bottomSide, start: [2, 24], end: [30, 24] }, 9)
  }
}
