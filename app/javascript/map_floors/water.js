// MapFloors::Water: a river, a pond. Under it, the floor of a neighbour (or deep water); its banks are drawn over it
import { ink, shoreWave, water } from "map_editor/palette"
import { waterPattern } from "map_editor/patterns"
import { createSvgElement } from "map_editor/svg"
import { drawSwatchTile } from "map_editor/swatch"

export default {
  key: "water",
  pattern: waterPattern,
  wallKey: null,
  liquid: true,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null,
  drawSwatch(svg) {
    drawSwatchTile(svg, water)
    createSvgElement("path", { d: "M3 21 Q10 17 16 20 T29 18", fill: "none", stroke: ink, "stroke-width": 1.6 }, svg)
    createSvgElement("path", { d: "M8 10 q2.5 -2 5 0 t5 0 M14 26 q2 -1.6 4 0 t4 0", fill: "none", stroke: shoreWave,
                               "stroke-width": 1.1, "stroke-linecap": "round" }, svg)
  }
}
