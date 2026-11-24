// The furniture of a map (MapObjects, family "furniture"), drawn from the prototype. Each drawing is centered on the
// object: length and depth are its size along and across, in units of the map (24 per cell), before it is turned.
// drawnOnTop: what blocks the way, drawn over the rest. glow: the radius of its light, in cells
import { noise } from "map_editor/noise"
import { rounded, polygonPath } from "map_editor/svg"
import { leafyOutline, shapeAdder } from "map_editor/object_shapes"
import * as palette from "map_editor/palette"

const { ink, wood, stone, paper } = palette

function drawTableTop(group, length, depth) {
  const add = shapeAdder(group)
  const seatCount = Math.max(1, Math.round(length / 24))
  for (let index = 0; index < seatCount; index++) {
    const seatX = -length / 2 + ((index + 0.5) * length) / seatCount - 3
    add("rect", { x: rounded(seatX), y: rounded(-depth / 2 + 1), width: 6, height: 4, fill: wood, stroke: ink, "stroke-width": 1.1 })
    add("rect", { x: rounded(seatX), y: rounded(depth / 2 - 5), width: 6, height: 4, fill: wood, stroke: ink, "stroke-width": 1.1 })
  }
  add("rect", { x: rounded(-length / 2 + 3), y: rounded(-depth / 2 + 5), width: rounded(length - 6), height: rounded(depth - 10),
                fill: wood, stroke: ink, "stroke-width": 1.7 })
  add("path", { d: `M${rounded(-length / 2 + 3)} -1.5 H${rounded(length / 2 - 3)} M${rounded(-length / 2 + 3)} 1.5 H${rounded(length / 2 - 3)}`,
                stroke: ink, "stroke-width": 0.6 })
}

// The slanted folds of a cover, from left to right
function drawBedCover(add, { left, right, top, height, strokeWidth }) {
  let folds = ""
  for (let foldX = left; foldX < right; foldX += 5) folds += `M${rounded(foldX)} ${rounded(top)} l4 ${rounded(height)} `
  add("path", { d: folds, stroke: ink, "stroke-width": strokeWidth })
}

export default {
  table: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -9, y: -6, width: 18, height: 12, fill: wood, stroke: ink, "stroke-width": 1.6 })
    add("path", { d: "M-9 -2 H9 M-9 2 H9", stroke: ink, "stroke-width": 0.6 })
    add("circle", { cx: 3, cy: -1, r: 1.6, fill: "none", stroke: ink, "stroke-width": 0.9 })
  } },
  large_table: { width: 2, height: 1, draw: drawTableTop },
  long_table: { width: 3, height: 1, draw: drawTableTop },
  banquet_table: { width: 4, height: 2, draw: drawTableTop },
  round_table: { width: 2, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 9
    for (let index = 0; index < 6; index++) {
      const angle = (index / 6) * Math.PI * 2 + 0.3
      const chairX = Math.cos(angle) * (radius + 4.5)
      const chairY = Math.sin(angle) * (radius + 4.5)
      add("rect", { x: rounded(chairX - 3.5), y: rounded(chairY - 3.5), width: 7, height: 7, rx: 1.5, fill: wood, stroke: ink,
                    "stroke-width": 1.1, transform: `rotate(${rounded((angle * 180) / Math.PI)} ${rounded(chairX)} ${rounded(chairY)})` })
    }
    add("circle", { cx: 0, cy: 0, r: rounded(radius), fill: wood, stroke: ink, "stroke-width": 1.8 })
    add("circle", { cx: 0, cy: 0, r: rounded(radius - 3), fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("circle", { cx: -3, cy: -2, r: 2, fill: "none", stroke: ink, "stroke-width": 0.9 })
    add("circle", { cx: 4, cy: 2.5, r: 1.6, fill: "none", stroke: ink, "stroke-width": 0.9 })
  } },
  chair: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -5, y: -3, width: 10, height: 9, fill: wood, stroke: ink, "stroke-width": 1.4 })
    add("rect", { x: -6, y: -7, width: 12, height: 3.5, fill: wood, stroke: ink, "stroke-width": 1.4 })
    add("path", { d: "M-3 1 H3", stroke: ink, "stroke-width": 0.6 })
  } },
  stool: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 5.5, fill: wood, stroke: ink, "stroke-width": 1.5 })
    add("circle", { cx: 0, cy: 0, r: 3, fill: "none", stroke: ink, "stroke-width": 0.6 })
  } },
  bench: { width: 2, height: 1, draw(group, length) {
    const add = shapeAdder(group)
    add("rect", { x: rounded(-length / 2 + 3), y: -3.5, width: rounded(length - 6), height: 7, fill: wood, stroke: ink, "stroke-width": 1.5 })
    add("path", { d: `M${rounded(-length / 2 + 3)} 0 H${rounded(length / 2 - 3)} M${rounded(-length / 2 + 6)} -3.5 V3.5 M${rounded(length / 2 - 6)} -3.5 V3.5`,
                  stroke: ink, "stroke-width": 0.6 })
  } },
  throne: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("path", { d: "M-9 -5 L-7 -10 L-3 -7 L0 -11 L3 -7 L7 -10 L9 -5Z", fill: palette.gold, stroke: ink, "stroke-width": 1.3,
                  "stroke-linejoin": "round" })
    add("rect", { x: -9, y: -5, width: 3.5, height: 13, fill: wood, stroke: ink, "stroke-width": 1.3 })
    add("rect", { x: 5.5, y: -5, width: 3.5, height: 13, fill: wood, stroke: ink, "stroke-width": 1.3 })
    add("rect", { x: -5.5, y: -5, width: 11, height: 12, fill: palette.mauve, stroke: ink, "stroke-width": 1.3 })
    add("rect", { x: -3.5, y: -3, width: 7, height: 8, rx: 1.5, fill: palette.velvet, stroke: ink, "stroke-width": 0.7 })
  } },
  bed: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    add("rect", { x: rounded(-length / 2 + 3), y: rounded(-depth / 2 + 3), width: rounded(length - 6), height: rounded(depth - 6),
                  fill: palette.mauve, stroke: ink, "stroke-width": 1.7 })
    add("rect", { x: rounded(-length / 2 + 5.5), y: rounded(-depth / 2 + 6), width: 7, height: rounded(depth - 12), rx: 2,
                  fill: paper, stroke: ink, "stroke-width": 1.1 })
    add("path", { d: `M${rounded(-length / 2 + 16)} ${rounded(-depth / 2 + 3)} V${rounded(depth / 2 - 3)}`, stroke: ink, "stroke-width": 1.2 })
    drawBedCover(add, { left: -length / 2 + 20, right: length / 2 - 4, top: -depth / 2 + 4, height: depth - 8, strokeWidth: 0.6 })
  } },
  double_bed: { width: 2, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 4
    const halfDepth = depth / 2 - 3
    add("rect", { x: rounded(-halfLength), y: rounded(-halfDepth), width: rounded(halfLength * 2), height: rounded(halfDepth * 2),
                  fill: palette.mauve, stroke: ink, "stroke-width": 1.7 })
    add("rect", { x: rounded(-halfLength), y: rounded(-halfDepth), width: rounded(halfLength * 2), height: 3, fill: stone,
                  stroke: ink, "stroke-width": 1.2 })
    ;[-halfLength / 2, halfLength / 2].forEach((pillowX) => add("rect", {
      x: rounded(pillowX - 6), y: rounded(-halfDepth + 5), width: 12, height: 6, rx: 2, fill: paper, stroke: ink, "stroke-width": 1
    }))
    add("path", { d: `M${rounded(-halfLength)} ${rounded(-halfDepth + 14)} H${rounded(halfLength)}`, stroke: ink, "stroke-width": 1.1 })
    drawBedCover(add, { left: -halfLength + 2, right: halfLength - 2, top: -halfDepth + 15, height: halfDepth * 2 - 16,
                         strokeWidth: 0.55 })
  } },
  rug: { width: 3, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    add("rect", { x: rounded(-length / 2 + 5), y: rounded(-depth / 2 + 4), width: rounded(length - 10), height: rounded(depth - 8),
                  fill: palette.mauve, stroke: ink, "stroke-width": 1.3 })
    add("rect", { x: rounded(-length / 2 + 8), y: rounded(-depth / 2 + 7), width: rounded(length - 16), height: rounded(depth - 14),
                  fill: palette.darkMauve, stroke: ink, "stroke-width": 0.7 })
    add("path", { d: `M0 ${rounded(-depth / 2 + 11)} L${rounded(length / 4)} 0 L0 ${rounded(depth / 2 - 11)} L${rounded(-length / 4)} 0Z`,
                  fill: palette.mauve, stroke: ink, "stroke-width": 0.8 })
    let fringe = ""
    for (let fringeY = -depth / 2 + 5; fringeY <= depth / 2 - 5; fringeY += 2.5) {
      fringe += `M${rounded(-length / 2 + 2)} ${rounded(fringeY)} h3 M${rounded(length / 2 - 5)} ${rounded(fringeY)} h3 `
    }
    add("path", { d: fringe, stroke: ink, "stroke-width": 0.6 })
  } },
  wardrobe: { width: 2, height: 1, drawnOnTop: true, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 2
    add("rect", { x: rounded(-length / 2 + 3), y: rounded(top), width: rounded(length - 6), height: 12, fill: wood, stroke: ink, "stroke-width": 1.7 })
    add("rect", { x: rounded(-length / 2 + 5), y: rounded(top + 2), width: rounded(length - 10), height: 8, fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("path", { d: `M0 ${rounded(top + 2)} V${rounded(top + 10)}`, stroke: ink, "stroke-width": 1 })
    add("circle", { cx: -2, cy: rounded(top + 6), r: 0.9, fill: ink })
    add("circle", { cx: 2, cy: rounded(top + 6), r: 0.9, fill: ink })
  } },
  bookcase: { width: 3, height: 1, drawnOnTop: true, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 2
    add("rect", { x: rounded(-length / 2 + 2), y: rounded(top), width: rounded(length - 4), height: 9, fill: wood, stroke: ink, "stroke-width": 1.6 })
    let books = ""
    for (let bookX = -length / 2 + 4.5, index = 0; bookX < length / 2 - 3; bookX += 2.2 + noise(seed, index, 70) * 1.4, index++) {
      books += `M${rounded(bookX)} ${rounded(top + 1.5 + noise(index, seed, 71) * 2.5)} V${rounded(top + 7.5)} `
    }
    add("path", { d: books, stroke: ink, "stroke-width": 0.9 })
  } },
  shelf: { width: 2, height: 1, drawnOnTop: true, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 2
    add("rect", { x: rounded(-length / 2 + 3), y: rounded(top), width: rounded(length - 6), height: 7, fill: wood, stroke: ink, "stroke-width": 1.5 })
    for (let itemX = -length / 2 + 6, index = 0; itemX < length / 2 - 5; itemX += 4 + noise(seed, index, 420) * 2, index++) {
      if (noise(seed, index, 421) < 0.5) {
        add("circle", { cx: rounded(itemX), cy: rounded(top + 3.5), r: 1.5, fill: "none", stroke: ink, "stroke-width": 0.8 })
      } else {
        add("rect", { x: rounded(itemX - 1.3), y: rounded(top + 1.8), width: 2.6, height: 3.4, fill: "none", stroke: ink, "stroke-width": 0.7 })
      }
    }
  } },
  chest: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -7, y: -5, width: 14, height: 10, fill: palette.gold, stroke: ink, "stroke-width": 1.6 })
    add("line", { x1: -7, y1: -1.5, x2: 7, y2: -1.5, stroke: ink, "stroke-width": 1.2 })
    add("rect", { x: -1.5, y: -2.8, width: 3, height: 3.5, fill: ink })
    add("path", { d: "M-4 -5 v10 M4 -5 v10", stroke: ink, "stroke-width": 0.7 })
  } },
  desk: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 2
    add("rect", { x: rounded(-length / 2 + 3), y: rounded(top), width: rounded(length - 6), height: 11, fill: wood, stroke: ink, "stroke-width": 1.7 })
    add("rect", { x: -9, y: rounded(top + 2), width: 8, height: 6, fill: wood, stroke: ink, "stroke-width": 0.7,
                  transform: `rotate(-8 -5 ${rounded(top + 5)})` })
    add("circle", { cx: 6, cy: rounded(top + 4), r: 1.6, fill: ink })
    add("path", { d: `M5 ${rounded(top + 3)} l5 -2`, stroke: ink, "stroke-width": 0.8 })
    add("rect", { x: -3.5, y: rounded(depth / 2 - 9), width: 7, height: 6, rx: 1, fill: wood, stroke: ink, "stroke-width": 1.1 })
  } },
  counter: { width: 3, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 1.5
    add("rect", { x: rounded(-length / 2 + 2), y: rounded(top), width: rounded(length - 4), height: 4.5, fill: wood, stroke: ink, "stroke-width": 1.2 })
    for (let mugX = -length / 2 + 5; mugX < length / 2 - 4; mugX += 3.2) {
      add("circle", { cx: rounded(mugX), cy: rounded(top + 2.25), r: 1.1, fill: "none", stroke: ink, "stroke-width": 0.7 })
    }
    add("rect", { x: rounded(-length / 2 + 2), y: rounded(top + 8), width: rounded(length - 4), height: 8, fill: wood, stroke: ink, "stroke-width": 1.8 })
    add("line", { x1: rounded(-length / 2 + 2), y1: rounded(top + 10), x2: rounded(length / 2 - 2), y2: rounded(top + 10), stroke: ink, "stroke-width": 0.6 })
    ;[-length / 4, 2, length / 4 + 3].forEach((stoolX) => add("circle", {
      cx: rounded(stoolX), cy: rounded(top + 13), r: 1.8, fill: wood, stroke: ink, "stroke-width": 0.9
    }))
  } },
  bathtub: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 3
    const halfDepth = depth / 2 - 3
    add("rect", { x: rounded(-halfLength), y: rounded(-halfDepth), width: rounded(halfLength * 2), height: rounded(halfDepth * 2),
                  rx: rounded(halfDepth), fill: wood, stroke: ink, "stroke-width": 1.6 })
    add("rect", { x: rounded(-halfLength + 3), y: rounded(-halfDepth + 3), width: rounded(halfLength * 2 - 6), height: rounded(halfDepth * 2 - 6),
                  rx: rounded(halfDepth - 3), fill: palette.water, stroke: ink, "stroke-width": 0.8 })
    add("path", { d: `M${rounded(-halfLength + 8)} -1 q2 -1.5 4 0 t4 0 M${rounded(halfLength - 18)} 2 q2 -1.5 4 0 t4 0`,
                  fill: "none", stroke: palette.ripple, "stroke-width": 0.7 })
  } },
  fireplace: { width: 2, height: 1, drawnOnTop: true, glow: 2.6, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 1
    add("rect", { x: rounded(-length / 2 + 2), y: rounded(top), width: rounded(length - 4), height: 12, fill: stone, stroke: ink, "stroke-width": 1.6 })
    let joints = `M${rounded(-length / 2 + 2)} ${rounded(top + 6)} H${rounded(-length / 4 - 1)} M${rounded(length / 4 + 1)} ${rounded(top + 6)} H${rounded(length / 2 - 2)} `
    ;[-length / 2 + 7, -length / 2 + 12, length / 2 - 7, length / 2 - 12].forEach((jointX, index) => {
      joints += `M${rounded(jointX)} ${rounded(top + (index % 2 ? 6 : 0))} v6 `
    })
    add("path", { d: joints, stroke: ink, "stroke-width": 0.7 })
    add("rect", { x: rounded(-length / 4), y: rounded(top), width: rounded(length / 2), height: 9, fill: palette.ember, stroke: ink, "stroke-width": 1.3 })
    add("path", { d: `M${rounded(-length / 4 + 2)} ${rounded(top + 7)} L${rounded(length / 4 - 2)} ${rounded(top + 5)} M${rounded(-length / 4 + 2)} ${rounded(top + 5)} L${rounded(length / 4 - 2)} ${rounded(top + 7)}`,
                  stroke: ink, "stroke-width": 1.4, "stroke-linecap": "round" })
    add("path", { d: `M0 ${rounded(top + 7)} C-3 ${rounded(top + 4)} -1 ${rounded(top + 2)} 0 ${rounded(top + 1)} C1 ${rounded(top + 3)} 3 ${rounded(top + 4)} 0 ${rounded(top + 7)}Z`,
                  fill: palette.flame, stroke: ink, "stroke-width": 0.9 })
    add("path", { d: `M${rounded(-length / 4 - 2)} ${rounded(top + 12)} A${rounded(length / 4 + 2)} 6 0 0 0 ${rounded(length / 4 + 2)} ${rounded(top + 12)}`,
                  fill: "none", stroke: ink, "stroke-width": 1, "stroke-dasharray": "2 1.5" })
  } },
  bread_oven: { width: 2, height: 2, glow: 1.8, draw(group, length, depth) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 3
    add("path", { d: `M${rounded(-radius)} ${rounded(radius * 0.6)} V0 A${rounded(radius)} ${rounded(radius)} 0 0 1 ${rounded(radius)} 0 V${rounded(radius * 0.6)} Z`,
                  fill: stone, stroke: ink, "stroke-width": 1.7, "stroke-linejoin": "round" })
    let bricks = ""
    for (let index = 1; index < 6; index++) {
      const angle = Math.PI + (index / 6) * Math.PI
      bricks += `M${rounded(Math.cos(angle) * radius * 0.5)} ${rounded(Math.sin(angle) * radius * 0.5)} L${rounded(Math.cos(angle) * radius)} ${rounded(Math.sin(angle) * radius)} `
    }
    add("path", { d: bricks, stroke: ink, "stroke-width": 0.8 })
    add("path", { d: `M${rounded(-radius * 0.4)} ${rounded(radius * 0.6)} V${rounded(radius * 0.1)} A${rounded(radius * 0.4)} ${rounded(radius * 0.4)} 0 0 1 ${rounded(radius * 0.4)} ${rounded(radius * 0.1)} V${rounded(radius * 0.6)} Z`,
                  fill: palette.ember, stroke: ink, "stroke-width": 1.2 })
    add("path", { d: `M0 ${rounded(radius * 0.5)} C-2.5 ${rounded(radius * 0.3)} -0.8 ${rounded(radius * 0.12)} 0 0 C0.8 ${rounded(radius * 0.12)} 2.5 ${rounded(radius * 0.3)} 0 ${rounded(radius * 0.5)} Z`,
                  fill: palette.flame, stroke: ink, "stroke-width": 0.8 })
  } },
  cauldron: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("path", { d: "M-9 -2 a2.5 2.5 0 0 1 0 4 M9 -2 a2.5 2.5 0 0 0 0 4", fill: "none", stroke: ink, "stroke-width": 1.3 })
    add("circle", { cx: 0, cy: 0, r: 8, fill: palette.iron, stroke: ink, "stroke-width": 2 })
    add("circle", { cx: 0, cy: 0, r: 5.5, fill: palette.brew, stroke: ink, "stroke-width": 0.8 })
    ;[[-2, -1.5, 1.3], [1.8, 0.8, 1], [-0.5, 2.4, 0.7]].forEach(([bubbleX, bubbleY, radius]) => add("circle", {
      cx: bubbleX, cy: bubbleY, r: radius, fill: "none", stroke: ink, "stroke-width": 0.7
    }))
  } },
  brazier: { width: 1, height: 1, glow: 2, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 7.5, fill: stone, stroke: ink, "stroke-width": 1.6 })
    add("circle", { cx: 0, cy: 0, r: 5, fill: palette.ember, stroke: ink, "stroke-width": 0.8 })
    ;[[-2, 1], [1.5, 1.8], [0, -1.5], [2.2, -0.8], [-2.4, -1.4]].forEach(([coalX, coalY]) => add("circle", {
      cx: coalX, cy: coalY, r: 1, fill: ink
    }))
    add("path", { d: "M0 2 C-3 -1 -1 -4 0 -6 C1 -3 3 -1 0 2Z", fill: palette.flame, stroke: ink, "stroke-width": 0.9 })
  } },
  candelabrum: { width: 1, height: 1, glow: 1.8, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 4, fill: stone, stroke: ink, "stroke-width": 1.3 })
    ;[[0, -7], [6.1, 3.5], [-6.1, 3.5]].forEach(([candleX, candleY]) => {
      add("line", { x1: 0, y1: 0, x2: candleX, y2: candleY, stroke: ink, "stroke-width": 1 })
      add("circle", { cx: candleX, cy: candleY, r: 2.4, fill: paper, stroke: ink, "stroke-width": 1 })
      add("circle", { cx: candleX, cy: candleY, r: 1, fill: palette.flame })
    })
  } },
  barrel: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 7.5, fill: wood, stroke: ink, "stroke-width": 1.6 })
    add("circle", { cx: 0, cy: 0, r: 5, fill: "none", stroke: ink, "stroke-width": 0.8 })
    add("path", { d: "M-4.5 -2 H4.5 M-4.8 1 H4.8", stroke: ink, "stroke-width": 0.7 })
  } },
  crate: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -8, y: -8, width: 16, height: 16, fill: wood, stroke: ink, "stroke-width": 1.6 })
    add("rect", { x: -5.5, y: -5.5, width: 11, height: 11, fill: "none", stroke: ink, "stroke-width": 0.7 })
    add("path", { d: "M-5.5 -5.5 L5.5 5.5 M5.5 -5.5 L-5.5 5.5", stroke: ink, "stroke-width": 1 })
  } },
  sacks: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    ;[[-3.5, -2, 5], [4, -1, 4.5], [0, 5, 4.2]].forEach(([sackX, sackY, radius], index) => {
      add("path", { d: leafyOutline(sackX, sackY, radius, 6, seed + index), fill: palette.burlap, stroke: ink, "stroke-width": 1.2,
                    "stroke-linejoin": "round" })
      add("path", { d: `M${rounded(sackX - 1.5)} ${rounded(sackY - radius + 1.5)} l1.5 1.5 l1.5 -1.5`, fill: "none", stroke: ink,
                    "stroke-width": 0.8 })
    })
  } },
  workbench: { width: 3, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 3
    add("rect", { x: rounded(-length / 2 + 2), y: rounded(top), width: rounded(length - 4), height: 12, fill: wood, stroke: ink, "stroke-width": 1.7 })
    add("path", { d: `M${rounded(-length / 2 + 2)} ${rounded(top + 4)} H${rounded(length / 2 - 2)}`, stroke: ink, "stroke-width": 0.6 })
    add("path", { d: `M${rounded(-length / 4 - 5)} ${rounded(top + 8)} H${rounded(-length / 4 + 4)} M${rounded(-length / 4 + 2)} ${rounded(top + 6)} V${rounded(top + 10)}`,
                  stroke: ink, "stroke-width": 1.3, "stroke-linecap": "round" })
    add("path", { d: `M-4 ${rounded(top + 9)} l2 -2 l2 2 l2 -2 l2 2 l2 -2`, fill: "none", stroke: ink, "stroke-width": 0.9 })
    add("circle", { cx: rounded(length / 4 + 4), cy: rounded(top + 7.5), r: 2.4, fill: "none", stroke: ink, "stroke-width": 1 })
    add("circle", { cx: rounded(length / 4 - 2), cy: rounded(top + 8), r: 1.2, fill: ink })
  } },
  anvil: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 1, r: 8.5, fill: palette.iron, stroke: ink, "stroke-width": 1.2 })
    add("circle", { cx: 0, cy: 1, r: 5.5, fill: "none", stroke: ink, "stroke-width": 0.5 })
    add("path", { d: "M-6 -3 H4 L10 -1 L4 1 V3 H-6 Z", fill: palette.steel, stroke: ink, "stroke-width": 1.4, "stroke-linejoin": "round" })
    add("line", { x1: -4, y1: -1, x2: 2, y2: -1, stroke: ink, "stroke-width": 0.6 })
  } },
  weapon_rack: { width: 2, height: 1, drawnOnTop: true, draw(group, length, depth) {
    const add = shapeAdder(group)
    const top = -depth / 2 + 2
    add("rect", { x: rounded(-length / 2 + 3), y: rounded(top), width: rounded(length - 6), height: 3.5, fill: wood, stroke: ink, "stroke-width": 1.4 })
    const weaponXs = [-length / 3, -length / 9, length / 9, length / 3]
    add("path", { d: weaponXs.map((weaponX) => `M${rounded(weaponX)} ${rounded(top + 3.5)} V${rounded(top + 15)} `).join(""),
                  stroke: ink, "stroke-width": 1.2, "stroke-linecap": "round" })
    add("path", { d: polygonPath([[weaponXs[0] - 2.5, top + 15], [weaponXs[0], top + 19], [weaponXs[0] + 2.5, top + 15]]),
                  fill: wood, stroke: ink, "stroke-width": 1 })
    add("path", { d: `M${rounded(weaponXs[1] - 3)} ${rounded(top + 7)} H${rounded(weaponXs[1] + 3)} M${rounded(weaponXs[2] - 3)} ${rounded(top + 7)} H${rounded(weaponXs[2] + 3)}`,
                  stroke: ink, "stroke-width": 1.2 })
    add("path", { d: `M${rounded(weaponXs[3])} ${rounded(top + 10)} a4 4 0 0 0 0 7 Z`, fill: wood, stroke: ink, "stroke-width": 1 })
  } },
  training_dummy: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("line", { x1: -9, y1: 0, x2: 9, y2: 0, stroke: ink, "stroke-width": 2.2, "stroke-linecap": "round" })
    add("circle", { cx: 0, cy: 0, r: 5, fill: palette.burlap, stroke: ink, "stroke-width": 1.5 })
    add("path", { d: "M-2.5 -2.5 l5 5 M2.5 -2.5 l-5 5", stroke: ink, "stroke-width": 0.9 })
  } },
  cage: { width: 1, height: 1, drawnOnTop: true, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -8, y: -8, width: 16, height: 16, fill: palette.iron, stroke: ink, "stroke-width": 1.7 })
    let bars = ""
    for (let barX = -5; barX <= 5; barX += 2.5) bars += `M${barX} -8 V8 `
    add("path", { d: bars, stroke: ink, "stroke-width": 0.9 })
    add("rect", { x: 5.5, y: -1.5, width: 3, height: 3, fill: ink })
  } }
}
