// The nature of a map (MapObjects, family "nature"), drawn from the prototype, like the furniture (map_objects/furniture)
import { noise, jitter } from "map_editor/noise"
import { rounded, polygonPath } from "map_editor/svg"
import { drawBoulder } from "map_editor/boulder"
import { leafyOutline, foliageBumps, drawShadeStrokes, leafPath, softOutline, shapeAdder } from "map_editor/object_shapes"
import * as palette from "map_editor/palette"

const { ink, paper, leaf, wood } = palette

// A star of needles, seen from above: points long and short in turn
function needlesPath(radius, pointCount, twist, seed, shiftX = 0, shiftY = 0) {
  const points = []
  for (let index = 0; index < pointCount * 2; index++) {
    const angle = (index / (pointCount * 2)) * Math.PI * 2 + twist
    const distance = index % 2 ? radius * 0.72 : radius * (0.95 + noise(seed, index, 260 + twist * 10) * 0.08)
    points.push([Math.cos(angle) * distance + shiftX, Math.sin(angle) * distance + shiftY])
  }
  return polygonPath(points)
}

// A wooden bridge across its length, its planks across, a rail and posts on each side
function drawBridge(group, length, depth) {
  const add = shapeAdder(group)
  const top = -depth / 2 + 4
  const bottom = depth / 2 - 4
  add("rect", { x: rounded(-length / 2), y: rounded(top), width: rounded(length), height: rounded(bottom - top), fill: wood })
  let planks = ""
  for (let plankX = -length / 2 + 2.5; plankX < length / 2; plankX += 3) planks += `M${rounded(plankX)} ${rounded(top)} V${rounded(bottom)} `
  add("path", { d: planks, stroke: ink, "stroke-width": 0.7 })
  add("path", { d: `M${rounded(-length / 2)} ${rounded(top)} H${rounded(length / 2)} M${rounded(-length / 2)} ${rounded(bottom)} H${rounded(length / 2)}`,
                stroke: ink, "stroke-width": 1.9, "stroke-linecap": "round" })
  ;[-length / 2 + 1, -length / 6, length / 6, length / 2 - 1].forEach((postX) => [top, bottom].forEach((postY) => add("rect", {
    x: rounded(postX - 1.5), y: rounded(postY - 1.5), width: 3, height: 3, fill: wood, stroke: ink, "stroke-width": 1
  })))
}

export default {
  tree: { width: 2, height: 2, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 2.5
    add("path", { d: leafyOutline(radius * 0.12, radius * 0.14, radius, 14, seed), fill: palette.objectShadow })
    add("path", { d: leafyOutline(0, 0, radius, 14, seed), fill: leaf, stroke: ink, "stroke-width": 1.7, "stroke-linejoin": "round" })
    add("path", { d: foliageBumps(0, 0, radius * 0.62, -2.6, 0.5, 5, seed) + foliageBumps(0, 0, radius * 0.3, 1.2, 3.6, 3, seed + 1),
                  fill: "none", stroke: ink, "stroke-width": 0.9, "stroke-linecap": "round" })
    drawShadeStrokes(group, 0, 0, radius, seed, 0.1, 1.8)
    drawShadeStrokes(group, 0, 0, radius * 0.75, seed + 3, 0.4, 1.4)
    let branches = ""
    for (let index = 0; index < 4; index++) {
      const angle = noise(seed, index, 250) * Math.PI * 2
      branches += `M0 0 L${rounded(Math.cos(angle) * radius * 0.22)} ${rounded(Math.sin(angle) * radius * 0.22)} `
    }
    add("path", { d: branches, stroke: ink, "stroke-width": 1, "stroke-linecap": "round" })
    add("circle", { cx: 0, cy: 0, r: 2, fill: ink })
  } },
  fir_tree: { width: 2, height: 2, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 2
    add("path", { d: needlesPath(radius, 16, 0, seed, 2, 2.5), fill: palette.objectShadow })
    ;[[radius, 16, 0], [radius * 0.7, 12, 0.2], [radius * 0.42, 8, 0.4]].forEach(([layerRadius, pointCount, twist], index) => add("path", {
      d: needlesPath(layerRadius, pointCount, twist, seed), fill: index === 1 ? palette.darkLeaf : leaf, stroke: ink, "stroke-width": 1.2,
      "stroke-linejoin": "round"
    }))
    let spokes = ""
    for (let index = 0; index < 8; index++) {
      const angle = (index / 8) * Math.PI * 2 + 0.2
      spokes += `M0 0 L${rounded(Math.cos(angle) * radius * 0.85)} ${rounded(Math.sin(angle) * radius * 0.85)} `
    }
    add("path", { d: spokes, stroke: ink, "stroke-width": 0.5, "stroke-dasharray": "2 2" })
    add("circle", { cx: 0, cy: 0, r: 1.8, fill: ink })
  } },
  bush: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    add("path", { d: leafyOutline(1.5, 1.5, 9, 9, seed), fill: palette.objectShadow })
    add("path", { d: leafyOutline(0, 0, 9, 9, seed), fill: leaf, stroke: ink, "stroke-width": 1.3, "stroke-linejoin": "round" })
    add("path", { d: foliageBumps(0, 0, 4.5, -2.2, 0.6, 3, seed), fill: "none", stroke: ink, "stroke-width": 0.8 })
    drawShadeStrokes(group, 0, 0, 8.5, seed)
  } },
  fern: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    let leaves = ""
    let veins = ""
    for (let index = 0; index < 7; index++) {
      const angle = (index / 7) * Math.PI * 2 + noise(seed, index, 230) * 0.4
      const leafLength = 8 + noise(seed, index, 231) * 3.5
      const cosine = Math.cos(angle)
      const sine = Math.sin(angle)
      leaves += leafPath(0, 0, angle, leafLength, 2.6)
      veins += `M0 0 L${rounded(cosine * leafLength * 0.9)} ${rounded(sine * leafLength * 0.9)} `
      for (let progress = 0.35; progress < 0.9; progress += 0.18) {
        const veinX = rounded(cosine * leafLength * progress)
        const veinY = rounded(sine * leafLength * progress)
        veins += `M${veinX} ${veinY} l${rounded((cosine - sine) * 1.5)} ${rounded((sine + cosine) * 1.5)} M${veinX} ${veinY} l${rounded((cosine + sine) * 1.5)} ${rounded((sine - cosine) * 1.5)} `
      }
    }
    add("path", { d: leaves, fill: leaf, stroke: ink, "stroke-width": 1, "stroke-linejoin": "round" })
    add("path", { d: veins, stroke: ink, "stroke-width": 0.55, "stroke-linecap": "round" })
    add("circle", { cx: 0, cy: 0, r: 1.6, fill: ink })
  } },
  stump: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    let roots = ""
    for (let index = 0; index < 5; index++) {
      const angle = (index / 5) * Math.PI * 2 + noise(seed, index, 240)
      roots += `M${rounded(Math.cos(angle) * 5.5)} ${rounded(Math.sin(angle) * 5.5)} q${rounded(Math.cos(angle + 0.5) * 3)} ${rounded(Math.sin(angle + 0.5) * 3)} ${rounded(Math.cos(angle) * 5)} ${rounded(Math.sin(angle) * 5)} `
    }
    add("path", { d: roots, fill: "none", stroke: ink, "stroke-width": 1.3, "stroke-linecap": "round" })
    add("circle", { cx: 0, cy: 0, r: 6.5, fill: paper, stroke: ink, "stroke-width": 1.5 })
    add("circle", { cx: 0.4, cy: -0.3, r: 4, fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("circle", { cx: 0.6, cy: -0.5, r: 1.8, fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("path", { d: "M2 -6 l-1.5 4", stroke: ink, "stroke-width": 0.7 })
  } },
  rock: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const shift = (salt) => jitter(seed, salt, 2.4)
    add("path", { d: `M${rounded(-8 + shift(1))} 3 C-9 ${rounded(-5 + shift(2))} -2 -9 4 ${rounded(-7 + shift(3))} C10 -5 10 4 6 7 C1 9 -6 8 ${rounded(-8 + shift(1))} 3Z`,
                  fill: palette.carvedStone, stroke: ink, "stroke-width": 1.6, "stroke-linejoin": "round" })
    add("path", { d: "M-3 5 l4 -4 M0 6 l5 -5 M3 6 l4 -4", stroke: ink, "stroke-width": 0.9, "stroke-linecap": "round" })
  } },
  boulder: { width: 2, height: 2, draw(group, length, depth, seed) {
    drawBoulder(group, 0, 0, Math.min(length, depth) / 2 - 3, seed)
  } },
  hay: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    add("path", { d: leafyOutline(0, 0, 9, 10, seed), fill: palette.hay, stroke: ink, "stroke-width": 1.3, "stroke-linejoin": "round" })
    let straws = ""
    for (let index = 0; index < 9; index++) {
      const strawX = (noise(seed, index, 500) - 0.5) * 12
      const strawY = (noise(seed, index, 501) - 0.5) * 12
      const angle = noise(seed, index, 502) * Math.PI
      straws += `M${rounded(strawX)} ${rounded(strawY)} l${rounded(Math.cos(angle) * 3)} ${rounded(Math.sin(angle) * 3)} `
    }
    add("path", { d: straws, stroke: ink, "stroke-width": 0.7, "stroke-linecap": "round" })
  } },
  puddle: { width: 1, height: 1, draw(group) {
    const add = shapeAdder(group)
    add("circle", { cx: 0, cy: 0, r: 11.5, fill: palette.puddle })
    let waves = ""
    for (let row = -1; row <= 1; row++) waves += `M-8 ${row * 6} q2 -2 4 0 t4 0 t4 0 t4 0 `
    add("path", { d: waves, fill: "none", stroke: ink, "stroke-width": 0.9, "stroke-linecap": "round" })
  } },
  pond: { width: 2, height: 2, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    const radius = Math.min(length, depth) / 2 - 3
    const points = []
    for (let index = 0; index < 8; index++) {
      const angle = (index / 8) * Math.PI * 2
      const distance = radius * (0.82 + noise(seed, index, 90) * 0.2)
      points.push([(Math.cos(angle) * distance * length) / Math.min(length, depth), Math.sin(angle) * distance])
    }
    add("path", { d: softOutline(points), fill: palette.water, stroke: ink, "stroke-width": 1.6 })
    let waves = ""
    for (let waveY = -radius / 2; waveY <= radius / 2; waveY += radius / 3) {
      waves += `M${rounded(-radius * 0.6)} ${rounded(waveY)} q3 -2 6 0 t6 0 t6 0 `
    }
    add("path", { d: waves, fill: "none", stroke: ink, "stroke-width": 0.8, "stroke-linecap": "round" })
  } },
  water_lilies: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    ;[[-4, -3, 4.2], [4, -1, 3.4], [-1, 5, 3]].forEach(([padX, padY, radius], index) => {
      const angle = noise(seed, index, 400) * Math.PI * 2
      add("path", { d: `M${rounded(padX)} ${rounded(padY)} L${rounded(padX + Math.cos(angle) * radius)} ${rounded(padY + Math.sin(angle) * radius)} A${radius} ${radius} 0 1 1 ${rounded(padX + Math.cos(angle + 0.6) * radius)} ${rounded(padY + Math.sin(angle + 0.6) * radius)} Z`,
                    fill: leaf, stroke: ink, "stroke-width": 1, "stroke-linejoin": "round" })
    })
    add("circle", { cx: -4, cy: -3, r: 1.3, fill: ink })
  } },
  reeds: { width: 1, height: 1, draw(group, length, depth, seed) {
    const add = shapeAdder(group)
    let stems = ""
    for (let index = 0; index < 8; index++) {
      const stemX = (noise(seed, index, 410) - 0.5) * 14
      const stemY = (noise(seed, index, 411) - 0.5) * 12
      const stemLength = 5 + noise(seed, index, 412) * 5
      const lean = (noise(seed, index, 413) - 0.5) * 4
      stems += `M${rounded(stemX)} ${rounded(stemY + stemLength / 2)} q${rounded(lean / 2)} ${rounded(-stemLength / 2)} ${rounded(lean)} ${rounded(-stemLength)} `
    }
    add("path", { d: stems, fill: "none", stroke: ink, "stroke-width": 0.9, "stroke-linecap": "round" })
    for (let index = 0; index < 3; index++) {
      const headX = (noise(seed, index, 414) - 0.5) * 10
      const headY = (noise(seed, index, 415) - 0.5) * 8
      add("ellipse", { cx: rounded(headX), cy: rounded(headY - 4), rx: 1.1, ry: 2.4, fill: ink })
    }
  } },
  campfire: { width: 1, height: 1, glow: 2.6, draw(group) {
    const add = shapeAdder(group)
    for (let index = 0; index < 7; index++) {
      const angle = (index / 7) * Math.PI * 2
      add("circle", { cx: rounded(Math.cos(angle) * 7.5), cy: rounded(Math.sin(angle) * 7.5), r: 2, fill: palette.ash, stroke: ink,
                      "stroke-width": 1 })
    }
    add("path", { d: "M0 3 C-4 0 -1 -3 0 -5 C1 -2 4 0 0 3Z", fill: palette.flame, stroke: ink, "stroke-width": 1.1 })
  } },
  tent: { width: 2, height: 2, draw(group, length, depth) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 6
    const halfDepth = depth / 2 - 6
    add("path", { d: `M${rounded(-halfLength - 4)} ${rounded(-halfDepth - 4)} l3 3 M${rounded(halfLength + 4)} ${rounded(-halfDepth - 4)} l-3 3 M${rounded(-halfLength - 4)} ${rounded(halfDepth + 4)} l3 -3 M${rounded(halfLength + 4)} ${rounded(halfDepth + 4)} l-3 -3`,
                  stroke: ink, "stroke-width": 0.8 })
    add("path", { d: polygonPath([[-halfLength, -halfDepth], [halfLength, -halfDepth], [halfLength, halfDepth], [-halfLength, halfDepth]]),
                  fill: paper, stroke: ink, "stroke-width": 1.6, "stroke-linejoin": "round" })
    add("path", { d: `M${rounded(-halfLength)} 0 H${rounded(halfLength)}`, stroke: ink, "stroke-width": 1.3 })
    let folds = ""
    for (let foldX = -halfLength + 3; foldX < halfLength; foldX += 3) folds += `M${rounded(foldX)} 0 L${rounded(foldX)} ${rounded(halfDepth)} `
    add("path", { d: folds, stroke: ink, "stroke-width": 0.55 })
    add("path", { d: `M${rounded(halfLength)} ${rounded(-halfDepth * 0.5)} L${rounded(halfLength + 4)} 0 L${rounded(halfLength)} ${rounded(halfDepth * 0.5)}`,
                  fill: paper, stroke: ink, "stroke-width": 1.1, "stroke-linejoin": "round" })
  } },
  small_bridge: { width: 2, height: 1, draw: drawBridge },
  bridge: { width: 3, height: 1, draw: drawBridge },
  long_bridge: { width: 4, height: 1, draw: drawBridge },
  wide_bridge: { width: 3, height: 2, draw: drawBridge },
  rowboat: { width: 2, height: 1, draw(group, length) {
    const add = shapeAdder(group)
    const halfLength = length / 2 - 3
    add("path", { d: `M${rounded(-halfLength)} -5 L${rounded(halfLength - 8)} -5 Q${rounded(halfLength)} -4 ${rounded(halfLength)} 0 Q${rounded(halfLength)} 4 ${rounded(halfLength - 8)} 5 L${rounded(-halfLength)} 5 Z`,
                  fill: wood, stroke: ink, "stroke-width": 1.6, "stroke-linejoin": "round" })
    add("path", { d: `M${rounded(-halfLength + 2)} -3 L${rounded(halfLength - 8)} -3 Q${rounded(halfLength - 3)} -2 ${rounded(halfLength - 3)} 0 Q${rounded(halfLength - 3)} 2 ${rounded(halfLength - 8)} 3 L${rounded(-halfLength + 2)} 3 Z`,
                  fill: "none", stroke: ink, "stroke-width": 0.6 })
    add("path", { d: "M-4 -5 V5 M6 -5 V5", stroke: ink, "stroke-width": 1.3 })
    add("path", { d: "M-1 -5 l-6 -5 M-1 5 l-6 5", stroke: ink, "stroke-width": 1.1, "stroke-linecap": "round" })
  } }
}
