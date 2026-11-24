// The twins, for the page, of the floors of app/models/map_floors (MapFloors): how each one is drawn and what it does
// to its sides. Changing one means changing the other
import room from "map_floors/room"
import stone from "map_floors/stone"
import enclosure from "map_floors/enclosure"
import water from "map_floors/water"
import outdoors from "map_floors/outdoors"
import openAir from "map_floors/open_air"

const mapFloors = { room: room, stone: stone, enclosure: enclosure, water: water, outdoors: outdoors, open_air: openAir }

// undefined for a key without a twin: the cell is drawn as empty ground
export function floorOf(key) {
  return mapFloors[key]
}

// Open air and water count as the outside for a walled floor
export function isAir(floor) {
  return Boolean(floor?.open || floor?.liquid)
}
