// MapFloors::OpenAir: open ground without any border. For a walled floor, it counts as the outside: a room drawn in
// the middle of a meadow gets its walls
import { createSvgElement } from "map_editor/svg"
import { grassPattern } from "map_editor/patterns"
import { grassSpeck } from "map_editor/palette"
import { drawSwatchTile } from "map_editor/swatch"

export default {
  key: "open_air",
  pattern: grassPattern,
  wallKey: null,
  open: true,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: { color: grassSpeck, bladeChance: 0.22 },
  drawSwatch(svg) {
    drawSwatchTile(svg, grassPattern)
    ;[[9, 9], [22, 12], [12, 23], [24, 24], [17, 17]].forEach(([x, y]) => createSvgElement("circle", {
      cx: x, cy: y, r: 0.8, fill: "#8a8072"
    }, svg))
  }
}
