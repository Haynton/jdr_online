// The outlines of an object in its own color (Anthony's request: like the bank of the water, a darker shade of its
// fill rather than black ink). The objects are drawn with the ink of the map (map_objects); once drawn, each line or
// dot of ink takes a dark shade of the fill of its own shape, or of the main color of the object when it has none
import { ink } from "map_editor/palette"

const hexColor = /^#[0-9a-f]{6}$/i
// How dark and how colored the outline is: dark enough to read on the paper and the floors, its hue kept
const outlineLightness = 0.36
const outlineSaturationMax = 0.55

export function inkInObjectColor(group) {
  const shapes = [...group.querySelectorAll("*")]
  const mainColor = shapes.map((shape) => ownFill(shape)).find(Boolean)
  if (!mainColor) return

  shapes.forEach((shape) => {
    const outline = darkShade(ownFill(shape) || mainColor)
    if (shape.getAttribute("stroke") === ink) shape.setAttribute("stroke", outline)
    if (shape.getAttribute("fill") === ink) shape.setAttribute("fill", darkShade(mainColor))
  })
}

// The fill of a shape when it is a plain color other than the ink (not none, not a pattern)
function ownFill(shape) {
  const fill = shape.getAttribute("fill")
  return fill && hexColor.test(fill) && fill !== ink ? fill : null
}

function darkShade(color) {
  const [hue, saturation] = hueAndSaturation(color)
  return hslToHex(hue, Math.min(outlineSaturationMax, saturation * 1.3 + 0.1), outlineLightness)
}

function hueAndSaturation(color) {
  const [red, green, blue] = [1, 3, 5].map((start) => parseInt(color.slice(start, start + 2), 16) / 255)
  const highest = Math.max(red, green, blue)
  const lowest = Math.min(red, green, blue)
  const spread = highest - lowest
  if (spread === 0) return [0, 0]

  const lightness = (highest + lowest) / 2
  const saturation = spread / (1 - Math.abs(2 * lightness - 1))
  if (highest === red) return [(60 * ((green - blue) / spread) + 360) % 360, saturation]
  if (highest === green) return [60 * ((blue - red) / spread + 2), saturation]
  return [60 * ((red - green) / spread + 4), saturation]
}

function hslToHex(hue, saturation, lightness) {
  const chroma = (1 - Math.abs(2 * lightness - 1)) * saturation
  const channel = (offset) => {
    const position = (offset + hue / 30) % 12
    const value = lightness - chroma / 2 * Math.max(-1, Math.min(position - 3, 9 - position, 1))
    return Math.round(value * 255).toString(16).padStart(2, "0")
  }
  return `#${channel(0)}${channel(8)}${channel(4)}`
}
