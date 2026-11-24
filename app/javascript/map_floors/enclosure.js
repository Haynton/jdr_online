// MapFloors::Enclosure: dirt ground, fenced by a low wall where it meets the empty ground or open air
import { dirtPattern } from "map_editor/patterns"
import { dirtSpeck } from "map_editor/palette"

export default {
  key: "enclosure",
  pattern: dirtPattern,
  wallKey: "low_wall",
  inkBorder: false,
  shadowsOutside: true,
  pebblesOutside: () => 1,
  rocksOutside: false,
  speckles: { color: dirtSpeck, bladeChance: 0.08 }
}
