// MapFloors::Room: a plank floor. Where it meets the empty ground (or open air), an ink wall, hatched outside
import { woodPattern } from "map_editor/patterns"

export default {
  key: "room",
  pattern: woodPattern,
  wallKey: null,
  inkBorder: true,
  shadowsOutside: true,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null
}
