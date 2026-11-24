// MapFloors::OpenAir: open ground without any border, its edge soft and irregular where it meets the empty ground.
// For a walled floor, it counts as the outside: a room drawn in the middle of a meadow gets its walls
import { grassPattern } from "map_editor/patterns"
import { grassSpeck } from "map_editor/palette"

export default {
  key: "open_air",
  pattern: grassPattern,
  wallKey: null,
  open: true,
  // Facing the empty ground, its edge is irregular and rounded (map_renderer, drawSoftEdgedFloors)
  softEdge: true,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: { color: grassSpeck, bladeChance: 0.22 }
}
