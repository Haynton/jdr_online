// MapFloors::Outdoors: grass among the rocks, the boulders piled where it meets the empty ground (a cave, a gorge)
import { drawBoulder } from "map_editor/boulder"
import { grassPattern } from "map_editor/patterns"
import { grassSpeck } from "map_editor/palette"
import { drawSwatchTile } from "map_editor/swatch"

const swatchBoulders = [[8, 8, 4], [16, 6, 3.5], [24, 9, 4.5], [7, 18, 3.5], [25, 21, 4], [13, 26, 4], [21, 26, 3]]

export default {
  key: "outdoors",
  pattern: grassPattern,
  wallKey: null,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: (depth) => 2 + depth,
  rocksOutside: true,
  speckles: { color: grassSpeck, bladeChance: 0.22 },
  drawSwatch(svg) {
    drawSwatchTile(svg, grassPattern)
    swatchBoulders.forEach(([x, y, radius], index) => drawBoulder(svg, x, y, radius, index + 11))
  }
}
