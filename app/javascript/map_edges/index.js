// The twins, for the page, of the edges of app/models/map_edges (MapEdges): how each one is drawn. Changing one means
// changing the other
import wall from "map_edges/wall"
import stoneWall from "map_edges/stone_wall"
import lowWall from "map_edges/low_wall"
import door from "map_edges/door"

const mapEdges = { wall: wall, stone_wall: stoneWall, low_wall: lowWall, door: door }

// undefined for a key without a twin: the edge is not drawn
export function edgeOf(key) {
  return mapEdges[key]
}

export const doorKey = door.key
