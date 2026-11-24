// The twins, for the page, of the objects of app/models/map_objects.rb (MapObjects): how each one is drawn, its size
// in cells (the same as in Ruby, checked by a test), whether it is drawn on top and its light. Changing one means
// changing the other
import furniture from "map_objects/furniture"
import decor from "map_objects/decor"
import nature from "map_objects/nature"
import { drawSwatchTile } from "map_editor/swatch"
import { cellSize } from "map_editor/square_grid"
import { createSvgElement } from "map_editor/svg"
import { inkInObjectColor } from "map_editor/object_ink"

const mapObjects = { ...furniture, ...decor, ...nature }

// undefined for a key without a twin: the object is not drawn
export function objectOf(key) {
  return mapObjects[key]
}

// Its size once turned (rotation: quarter turns): [columns, rows]
export function footprintSize(mapObject, rotation) {
  return rotation % 2 ? [mapObject.height, mapObject.width] : [mapObject.width, mapObject.height]
}

// Draws an object into a group, centered on it, then gives its outlines its own color (map_editor/object_ink): on the
// map and on the swatch of its tool alike
export function drawObject(group, mapObject, length, depth, seed) {
  mapObject.draw(group, length, depth, seed)
  inkInObjectColor(group)
}

// The swatch of a tool of the tab Objects: the object on a tile, a large one shrunk to fit
export function drawObjectSwatch(svg, key) {
  const mapObject = objectOf(key)
  drawSwatchTile(svg)
  const length = cellSize * mapObject.width
  const depth = cellSize * mapObject.height
  const scale = mapObject.width === 1 && mapObject.height === 1 ? 1 : 25 / Math.max(length, depth)
  drawObject(createSvgElement("g", { transform: `translate(16 16) scale(${scale.toFixed(3)})` }, svg), mapObject, length, depth, 5)
}
