// MapFloors::Outdoors: grass among the rocks, the boulders piled where it meets the empty ground (a cave, a gorge)
import { grassPattern } from "map_editor/patterns"
import { grassSpeck } from "map_editor/palette"

export default {
  key: "outdoors",
  pattern: grassPattern,
  wallKey: null,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: (depth) => 2 + depth,
  rocksOutside: true,
  speckles: { color: grassSpeck, bladeChance: 0.22 }
}
