// The textures of the floors, drawn once in the <defs> of the board: planks, paving stones, grass, dirt, water. A
// floor fills its cells with one of them (fill: "url(#map-pattern-wood)", map_floors). The ids are those of the page:
// the swatches of the tools use them too
import { noise } from "map_editor/noise"
import { createSvgElement, rounded } from "map_editor/svg"

export const woodPattern = "url(#map-pattern-wood)"
export const stonePattern = "url(#map-pattern-stone)"
export const grassPattern = "url(#map-pattern-grass)"
export const dirtPattern = "url(#map-pattern-dirt)"
export const waterPattern = "url(#map-pattern-water)"
export const glowGradient = "url(#map-glow)"
export const objectShadowFilter = "url(#map-shadow)"

const woodTones = ["#e6d3b9", "#e3cfb4", "#e9d7be", "#e0ccb0", "#e5d1b6", "#e8d5bb"]
const stoneTones = ["#ebe6da", "#e8e2d5", "#eee9de", "#e5dfd1", "#eae4d8"]

export function addMapPatterns(svg) {
  const definitions = createSvgElement("defs", {}, svg)
  const pattern = (id, width, height) => createSvgElement("pattern", {
    id: `map-pattern-${id}`, width, height, patternUnits: "userSpaceOnUse"
  }, definitions)

  drawRowsOfBoards(pattern("wood", 168, 48), { width: 168, rowHeight: 8, rowCount: 6, seed: 201, tones: woodTones,
                                               line: "#a88d6c", cornerRadius: 0 })
  drawRowsOfBoards(pattern("stone", 96, 72), { width: 96, rowHeight: 18, rowCount: 4, seed: 211, tones: stoneTones,
                                               line: "#aba190", cornerRadius: 2.5 })
  drawBlotches(pattern("grass", 120, 120), { base: "#dde3c4", tones: ["#d6ddbb", "#e3e8cd", "#d2d9b6", "#dfe4c7"],
                                             count: 16, seed: 221 }, drawGrassBlades)
  drawBlotches(pattern("dirt", 120, 120), { base: "#ece1ca", tones: ["#e6dac1", "#f0e6d1", "#e8dcc4"],
                                            count: 14, seed: 231 }, drawDirtSpecks)
  drawBlotches(pattern("water", 120, 120), { base: "#c9dfdc", tones: ["#d2e6e3", "#c1d8d5", "#cde3e0"],
                                             count: 14, seed: 241 }, () => {})
  addShadowFilter(definitions)
  addGlowGradient(definitions)
}

// The light around a fire, a brazier, a candelabrum: warm at the center, gone at the edge
function addGlowGradient(definitions) {
  const gradient = createSvgElement("radialGradient", { id: "map-glow" }, definitions)
  ;[[0, "#f6dca6", 0.22], [0.45, "#e8b979", 0.08], [1, "#e8b979", 0]].forEach(([offset, color, opacity]) => {
    createSvgElement("stop", { offset, "stop-color": color, "stop-opacity": opacity }, gradient)
  })
}

// Rows of boards (planks, paving stones), three per row at varying lengths, repeated on the side
function drawRowsOfBoards(pattern, { width, rowHeight, rowCount, seed, tones, line, cornerRadius }) {
  for (let row = 0; row < rowCount; row++) {
    const joints = [0, 1, 2].map((index) => ((index + noise(row, index, seed) * 0.7) * width) / 3).sort((a, b) => a - b)
    joints.forEach((jointX, index) => {
      const nextJointX = index < 2 ? joints[index + 1] : joints[0] + width
      const fill = tones[Math.floor(noise(row, index, seed + 1) * tones.length)]
      ;[jointX, jointX - width].forEach((boardX) => createSvgElement("rect", {
        x: rounded(boardX), y: row * rowHeight, width: rounded(nextJointX - jointX), height: rowHeight,
        rx: cornerRadius, fill, stroke: line, "stroke-width": 0.75, "stroke-opacity": 0.55
      }, pattern))
    })
  }
}

// Soft blotches of color on a base, wrapped around the edges of the pattern so that it repeats without a seam
function drawBlotches(pattern, { base, tones, count, seed }, drawMarks) {
  const size = 120
  createSvgElement("rect", { width: size, height: size, fill: base }, pattern)
  for (let index = 0; index < count; index++) {
    const x = noise(index, 1, seed) * size
    const y = noise(index, 2, seed) * size
    const radiusX = 7 + noise(index, 3, seed) * 13
    const radiusY = 5 + noise(index, 4, seed) * 9
    const angle = Math.round(noise(index, 5, seed) * 180)
    wrapAround(size, x, y, (wrappedX, wrappedY) => createSvgElement("ellipse", {
      cx: rounded(wrappedX), cy: rounded(wrappedY), rx: rounded(radiusX), ry: rounded(radiusY),
      fill: tones[index % tones.length], "fill-opacity": 0.55,
      transform: `rotate(${angle} ${rounded(wrappedX)} ${rounded(wrappedY)})`
    }, pattern))
  }
  drawMarks(pattern, size)
}

function drawGrassBlades(pattern, size) {
  for (let index = 0; index < 12; index++) {
    const x = noise(index, 6, 222) * size
    const y = noise(index, 7, 222) * size
    wrapAround(size, x, y, (wrappedX, wrappedY) => createSvgElement("path", {
      d: `M${rounded(wrappedX - 2)} ${rounded(wrappedY)} l1 -3 M${rounded(wrappedX)} ${rounded(wrappedY)} v-3.6 M${rounded(wrappedX + 2)} ${rounded(wrappedY)} l-1 -3`,
      stroke: "#a8b285", "stroke-width": 0.7, "stroke-linecap": "round", fill: "none"
    }, pattern))
  }
}

function drawDirtSpecks(pattern, size) {
  for (let index = 0; index < 16; index++) {
    const x = noise(index, 6, 232) * size
    const y = noise(index, 7, 232) * size
    wrapAround(size, x, y, (wrappedX, wrappedY) => createSvgElement("ellipse", {
      cx: rounded(wrappedX), cy: rounded(wrappedY), rx: 1.3, ry: 0.9, fill: "#bba886"
    }, pattern))
  }
}

function wrapAround(size, x, y, draw) {
  ;[[0, 0], [-size, 0], [0, -size], [-size, -size]].forEach(([shiftX, shiftY]) => draw(x + shiftX, y + shiftY))
}

// The soft shadow under what stands on the map
function addShadowFilter(definitions) {
  const filter = createSvgElement("filter", { id: "map-shadow", x: "-5%", y: "-5%", width: "110%", height: "110%" },
                                  definitions)
  createSvgElement("feDropShadow", { dx: 1, dy: 1.7, stdDeviation: 1.1, "flood-color": "#2a1f16",
                                     "flood-opacity": 0.18 }, filter)
}
