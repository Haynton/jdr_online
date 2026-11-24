// MapFloors::Water: a river, a pond. Under it, the floor of a neighbour (or deep water); its banks are drawn over it
import { waterPattern } from "map_editor/patterns"

export default {
  key: "water",
  pattern: waterPattern,
  wallKey: null,
  liquid: true,
  inkBorder: false,
  shadowsOutside: false,
  pebblesOutside: () => 0,
  rocksOutside: false,
  speckles: null
}
