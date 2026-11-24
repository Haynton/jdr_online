// The decor of a map (MapObjects, family "decor"), drawn from the prototype, like the furniture (map_objects/furniture)
import { rounded, polygonPath } from "map_editor/svg"
import { shapeAdder } from "map_editor/object_shapes"
import * as palette from "map_editor/palette"

const { ink, stone, paper, carvedStone } = palette

export default {
  column: { width: 1, height: 1, drawnOnTop: true, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 1.2, r: 6.5, fill: "#cfc7ba" })
    add("circle", { cx: 0, cy: 0, r: 6.5, fill: carvedStone, stroke: ink, "stroke-width": 1.8 })
    add("path", { d: "M-3.5 2 a4 4 0 0 0 7 0", fill: "none", stroke: ink, "stroke-width": 0.9 })
  } },
  statue: { width: 1, height: 1, drawnOnTop: true, draw(group) {
    const add = shapeAdder(group)
    add("rect", { x: -8, y: -8, width: 16, height: 16, fill: carvedStone, stroke: ink, "stroke-width": 1.6 })
    add("circle", { cx: 0, cy: 0, r: 4.5, fill: "none", stroke: ink, "stroke-width": 1.3 })
    add("path", { d: "M-8 -8 l3 3 M8 -8 l-3 3 M-8 8 l3 -3 M8 8 l-3 -3", stroke: ink, "stroke-width": 0.8 })
  } },
  altar: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    add("rect", { x: rounded(-length / 2 + 4), y: rounded(-depth / 2 + 4), width: rounded(length - 8), height: rounded(depth - 8),
                  fill: stone, stroke: ink, "stroke-width": 1.7 })
    add("rect", { x: rounded(-length / 2 + 7), y: rounded(-depth / 2 + 7), width: rounded(length - 14), height: rounded(depth - 14),
                  fill: "none", stroke: ink, "stroke-width": 0.7 })
    ;[-length / 4, length / 4].forEach((candleX) => {
      add("circle", { cx: rounded(candleX), cy: 0, r: 2.2, fill: palette.gold, stroke: ink, "stroke-width": 1 })
      add("circle", { cx: rounded(candleX), cy: 0, r: 0.7, fill: ink })
    })
  } },
  sarcophagus: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 3
    const halfDepth = depth / 2 - 3
    const outline = [[-halfLength, -halfDepth * 0.55], [-halfLength + 7, -halfDepth], [halfLength - 2, -halfDepth * 0.75],
                     [halfLength, 0], [halfLength - 2, halfDepth * 0.75], [-halfLength + 7, halfDepth], [-halfLength, halfDepth * 0.55]]
    add("path", { d: polygonPath(outline), fill: stone, stroke: ink, "stroke-width": 1.6, "stroke-linejoin": "round" })
    add("path", { d: polygonPath(outline.map(([pointX, pointY]) => [pointX * 0.82, pointY * 0.72])), fill: "none", stroke: ink,
                  "stroke-width": 0.7 })
    add("path", { d: `M${rounded(-halfLength + 6)} 0 H${rounded(halfLength - 6)} M${rounded(-halfLength + 10)} -3 V3`, stroke: ink,
                  "stroke-width": 0.9, "stroke-linecap": "round" })
    add("circle", { cx: rounded(-halfLength + 5), cy: 0, r: 2.2, fill: "none", stroke: ink, "stroke-width": 0.9 })
  } },
  grave: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 3
    const halfDepth = depth / 2 - 4
    add("rect", { x: rounded(-halfLength), y: rounded(-halfDepth), width: rounded(halfLength * 2), height: rounded(halfDepth * 2), rx: 2,
                  fill: stone, stroke: ink, "stroke-width": 1.5 })
    add("path", { d: `M${rounded(-halfLength + 4)} 0 H${rounded(-halfLength + 12)} M${rounded(-halfLength + 8)} -4 V4`, stroke: ink,
                  "stroke-width": 1.3, "stroke-linecap": "round" })
    let soil = ""
    for (let soilX = -halfLength + 16; soilX < halfLength - 2; soilX += 4) {
      soil += `M${rounded(soilX)} ${rounded(-halfDepth + 2)} l2 ${rounded(halfDepth * 2 - 4)} `
    }
    add("path", { d: soil, stroke: ink, "stroke-width": 0.5 })
  } },
  fountain: { width: 2, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 3
    add("circle", { cx: 0, cy: 0, r: rounded(radius), fill: stone, stroke: ink, "stroke-width": 1.7 })
    add("circle", { cx: 0, cy: 0, r: rounded(radius - 4), fill: palette.water, stroke: ink, "stroke-width": 1 })
    add("circle", { cx: 0, cy: 0, r: rounded(radius * 0.3), fill: stone, stroke: ink, "stroke-width": 1.3 })
    add("circle", { cx: 0, cy: 0, r: rounded(radius * 0.12), fill: palette.water, stroke: ink, "stroke-width": 0.8 })
    add("path", { d: `M${rounded(-radius * 0.65)} ${rounded(-radius * 0.2)} q2.5 -2 5 0 t5 0 M${rounded(radius * 0.3)} ${rounded(radius * 0.45)} q2.5 -2 5 0 t5 0`,
                  fill: "none", stroke: palette.ripple, "stroke-width": 0.8 })
  } },
  well: { width: 1, height: 1, drawnOnTop: true, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 9.5, fill: stone, stroke: ink, "stroke-width": 1.5 })
    add("circle", { cx: 0, cy: 0, r: 6, fill: palette.water, stroke: ink, "stroke-width": 1.2 })
    let stones = ""
    for (let index = 0; index < 10; index++) {
      const angle = (index / 10) * Math.PI * 2
      stones += `M${rounded(Math.cos(angle) * 6)} ${rounded(Math.sin(angle) * 6)} L${rounded(Math.cos(angle) * 9.5)} ${rounded(Math.sin(angle) * 9.5)} `
    }
    add("path", { d: stones, stroke: ink, "stroke-width": 0.7 })
    add("path", { d: "M-3 -1 q1.5 -1 3 0 t3 0 M-2 2 q1 -1 2 0 t2 0", fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("line", { x1: -11, y1: 0, x2: 11, y2: 0, stroke: ink, "stroke-width": 1.6 })
    add("rect", { x: -12.5, y: -1.8, width: 3, height: 3.6, fill: carvedStone, stroke: ink, "stroke-width": 1 })
    add("rect", { x: 9.5, y: -1.8, width: 3, height: 3.6, fill: carvedStone, stroke: ink, "stroke-width": 1 })
  } },
  stairs: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("path", { d: "M-10 -10 V10 M10 -10 V10", stroke: ink, "stroke-width": 1.5 })
    let steps = ""
    for (let index = 0; index < 6; index++) steps += `M-10 ${rounded(-8 + index * 3.4)} H10 `
    add("path", { d: steps, stroke: ink, "stroke-width": 1.1 })
    add("path", { d: "M0 6 V-5 M-3 -2 L0 -5 L3 -2", stroke: ink, "stroke-width": 1.3, fill: "none", "stroke-linecap": "round",
                  "stroke-linejoin": "round" })
  } },
  spiral_stairs: { width: 2, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 2
    const coreRadius = radius * 0.2
    const firstAngle = -Math.PI / 2
    const pointAt = (angle, distance) => `${rounded(Math.cos(angle) * distance)} ${rounded(Math.sin(angle) * distance)}`
    add("circle", { cx: 0, cy: 0, r: rounded(radius + 1.5), fill: stone, stroke: ink, "stroke-width": 1.6 })
    add("circle", { cx: 0, cy: 0, r: rounded(radius - 1.5), fill: paper, stroke: ink, "stroke-width": 0.8 })
    let steps = ""
    for (let index = 0; index <= 14; index++) {
      const angle = firstAngle + (index / 14) * Math.PI * 1.6
      steps += `M${pointAt(angle, coreRadius)} L${pointAt(angle, radius - 1.5)} `
    }
    add("path", { d: steps, stroke: ink, "stroke-width": 1 })
    const lastAngle = firstAngle + Math.PI * 1.6
    add("path", { d: `M${pointAt(lastAngle, radius - 1.5)} A${rounded(radius - 1.5)} ${rounded(radius - 1.5)} 0 0 1 ${pointAt(firstAngle, radius - 1.5)} L0 0 Z`,
                  fill: palette.spiralShade, stroke: "none" })
    add("circle", { cx: 0, cy: 0, r: rounded(coreRadius), fill: stone, stroke: ink, "stroke-width": 1.4 })
    const middleAngle = firstAngle + Math.PI * 0.8
    const arrowRadius = radius * 0.6
    add("path", { d: `M${pointAt(middleAngle - 0.35, arrowRadius)} A${rounded(arrowRadius)} ${rounded(arrowRadius)} 0 0 1 ${pointAt(middleAngle + 0.35, arrowRadius)}`,
                  fill: "none", stroke: ink, "stroke-width": 1.2, "stroke-linecap": "round" })
  } },
  ladder: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("path", { d: "M-4 -10 V10 M4 -10 V10", stroke: ink, "stroke-width": 1.6, "stroke-linecap": "round" })
    let rungs = ""
    for (let rungY = -7; rungY <= 7; rungY += 3.5) rungs += `M-4 ${rungY} H4 `
    add("path", { d: rungs, stroke: ink, "stroke-width": 1.1 })
  } },
  trap: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 8, fill: palette.trapRed, stroke: ink, "stroke-width": 1.5 })
    const starPoints = [0, 1, 2, 3, 4].map((index) => {
      const angle = -Math.PI / 2 + (index * 4 * Math.PI) / 5
      return [Math.cos(angle) * 7, Math.sin(angle) * 7]
    })
    add("path", { d: polygonPath(starPoints), fill: "none", stroke: ink, "stroke-width": 0.9, "stroke-linejoin": "round" })
  } },
  bones: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("path", { d: "M-5 0 a5 5 0 1 1 10 0 v2.5 h-2 v2 h-6 v-2 h-2Z", fill: carvedStone, stroke: ink, "stroke-width": 1.3,
                  "stroke-linejoin": "round" })
    add("circle", { cx: -2, cy: -0.5, r: 1.3, fill: ink })
    add("circle", { cx: 2, cy: -0.5, r: 1.3, fill: ink })
    add("path", { d: "M-9 8 L-3 5 M4 6 L9 9", stroke: ink, "stroke-width": 1.2, "stroke-linecap": "round" })
  } },
  cart: { width: 2, height: 1, draw(group, length, depth) {
    const add = shapeAdder(group)
    const { wood } = palette
    add("path", { d: `M${rounded(length / 2 - 14)} -2.5 L${rounded(length / 2 - 1)} -1 M${rounded(length / 2 - 14)} 2.5 L${rounded(length / 2 - 1)} 1`,
                  stroke: ink, "stroke-width": 1.2, "stroke-linecap": "round" })
    add("rect", { x: -3, y: rounded(-depth / 2 + 1.5), width: 8, height: 3, fill: wood, stroke: ink, "stroke-width": 1.1 })
    add("rect", { x: -3, y: rounded(depth / 2 - 4.5), width: 8, height: 3, fill: wood, stroke: ink, "stroke-width": 1.1 })
    add("rect", { x: rounded(-length / 2 + 4), y: rounded(-depth / 2 + 5), width: rounded(length - 18), height: rounded(depth - 10),
                  fill: wood, stroke: ink, "stroke-width": 1.6 })
    let planks = ""
    for (let plankY = -depth / 2 + 8; plankY < depth / 2 - 5; plankY += 3) {
      planks += `M${rounded(-length / 2 + 4)} ${rounded(plankY)} H${rounded(length / 2 - 14)} `
    }
    add("path", { d: planks, stroke: ink, "stroke-width": 0.6 })
  } }
}
