// MapFloors::Stone: paving stones, walled in stone where they meet the empty ground or open air
import { stonePattern } from "map_editor/patterns"

export default {
  key: "stone",
  pattern: stonePattern,
  wallKey: "stone_wall",
  inkBorder: false,
  shadowsOutside: true,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null
}
