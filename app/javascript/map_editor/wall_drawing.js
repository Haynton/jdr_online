// How a wall is drawn along a side of a cell: in ink (the walls of a room), in stones, as a low wall of piled stones,
// or as a door in one of them. A side runs from start to end; its normal (normalX, normalY) points out of its cell.
// Each end either goes on along the side (extension, to meet a wall that crosses it) or is cut along a miter (miter,
// to join the next wall of an outline)
import { ink, stone, rock, timber, lowWallMortar, doorWood } from "map_editor/palette"
import { noise } from "map_editor/noise"
import { createSvgElement, polygonPath, rounded } from "map_editor/svg"

export const stoneWallThickness = 7
export const lowWallThickness = 13
export const straightEnd = { extension: 0 }

// The ink and the timber of the walls of a group, drawn in two layers: all the ink under all the timber, so that
// walls that meet look like one
const inkLayers = new WeakMap()

export function drawInkWall(group, start, end, width = 2.8) {
  if (!inkLayers.has(group)) {
    inkLayers.set(group, [createSvgElement("g", { stroke: ink, "stroke-linecap": "round" }, group),
                          createSvgElement("g", { stroke: timber, "stroke-linecap": "round" }, group)])
  }
  const [inkLayer, timberLayer] = inkLayers.get(group)
  const line = { x1: rounded(start[0]), y1: rounded(start[1]), x2: rounded(end[0]), y2: rounded(end[1]) }
  createSvgElement("line", { ...line, "stroke-width": rounded(width * 2.2) }, inkLayer)
  createSvgElement("line", { ...line, "stroke-width": rounded(width * 2.2 - 2.4) }, timberLayer)
}

export function drawStoneWall(group, side, seed, startEnd = straightEnd, endEnd = straightEnd) {
  const { start, end, normalX, normalY } = side
  const along = unitVector(start, end)
  const length = Math.hypot(end[0] - start[0], end[1] - start[1])
  const corner = (point, wallEnd, direction, depth) => (wallEnd.miter
    ? [point[0] + wallEnd.miter[0] * depth, point[1] + wallEnd.miter[1] * depth]
    : [point[0] + direction * along[0] * wallEnd.extension + normalX * depth,
       point[1] + direction * along[1] * wallEnd.extension + normalY * depth])
  const half = stoneWallThickness / 2
  const outline = [corner(start, startEnd, -1, -half), corner(end, endEnd, 1, -half),
                   corner(end, endEnd, 1, half), corner(start, startEnd, -1, half)]
  createSvgElement("path", { d: polygonPath(outline), fill: stone, stroke: ink, "stroke-width": 1.4,
                             "stroke-linejoin": "round" }, group)
  const pointAt = (distance, depth) => [start[0] + along[0] * distance + normalX * depth,
                                        start[1] + along[1] * distance + normalY * depth]
  const middleStart = midpoint(outline[0], outline[3])
  const middleEnd = midpoint(outline[1], outline[2])
  let joints = `M${rounded(middleStart[0])} ${rounded(middleStart[1])} L${rounded(middleEnd[0])} ${rounded(middleEnd[1])} `
  ;[[-half, 0, 0], [0, half, 1]].forEach(([fromDepth, toDepth, row]) => {
    for (let distance = 1.5 + noise(seed, row, 101) * 4, index = 0; distance < length - 1.5;
      distance += 4.5 + noise(seed, index + row * 9, 102) * 4, index++) {
      const from = pointAt(distance, fromDepth)
      const to = pointAt(distance + (noise(seed, index, 103) - 0.5) * 1.2, toDepth)
      joints += `M${rounded(from[0])} ${rounded(from[1])} L${rounded(to[0])} ${rounded(to[1])} `
    }
  })
  createSvgElement("path", { d: joints, stroke: ink, "stroke-width": 0.8, "stroke-linecap": "round" }, group)
}

// A low wall: stones of varying sizes on a mortar, one or two per course
export function drawLowWall(group, side, seed, startEnd = straightEnd, endEnd = straightEnd) {
  const { start, end, normalX, normalY } = side
  const along = unitVector(start, end)
  const length = Math.hypot(end[0] - start[0], end[1] - start[1])
  const half = lowWallThickness / 2
  const distanceAtEnd = (wallEnd, depth, atEnd) => (wallEnd.miter
    ? (atEnd ? length : 0) + (wallEnd.miter[0] * along[0] + wallEnd.miter[1] * along[1]) * depth
    : (atEnd ? length + wallEnd.extension : -wallEnd.extension))
  const pointAt = (distance, depth) => [start[0] + along[0] * distance + normalX * depth,
                                        start[1] + along[1] * distance + normalY * depth]
  const mortarDepth = half - 1.5
  createSvgElement("path", { d: polygonPath([
    pointAt(distanceAtEnd(startEnd, -mortarDepth, false), -mortarDepth),
    pointAt(distanceAtEnd(endEnd, -mortarDepth, true), -mortarDepth),
    pointAt(distanceAtEnd(endEnd, mortarDepth, true), mortarDepth),
    pointAt(distanceAtEnd(startEnd, mortarDepth, false), mortarDepth)
  ]), fill: lowWallMortar }, group)
  const firstDistance = Math.min(distanceAtEnd(startEnd, -half, false), distanceAtEnd(startEnd, half, false))
  const lastDistance = Math.max(distanceAtEnd(endEnd, -half, true), distanceAtEnd(endEnd, half, true))
  layStones({ group, seed, pointAt, firstDistance, lastDistance, half })
}

function layStones({ group, seed, pointAt, firstDistance, lastDistance, half }) {
  let distance = firstDistance - noise(seed, 0, 300) * 3
  for (let course = 0; distance < lastDistance - 1.5; course++) {
    const stoneLength = 7 + noise(seed, course, 301) * 5
    const from = Math.max(distance, firstDistance)
    const to = Math.min(distance + stoneLength, lastDistance)
    if (to - from > 2.5) layCourse({ group, seed, pointAt, from, to, half, course })
    distance += stoneLength + 0.3
  }
}

// A course holds one stone across the wall, or now and then two, one beside the other
function layCourse({ group, seed, pointAt, from, to, half, course }) {
  const pinch = (noise(seed, course, 304) - 0.5) * 2
  const drawOne = (start, end, fromDepth, toDepth, stoneIndex) => drawLowWallStone(group, {
    seed, pointAt, from: start, to: end, fromDepth, toDepth, stoneIndex
  })
  if (noise(seed, course, 305) < 0.28 && to - from > 5) {
    drawOne(from, to, -half + pinch * 0.4, 0.3, course * 2)
    drawOne(from + 0.8, to - 0.4, 0.3, half + pinch * 0.4, course * 2 + 1)
    return
  }
  drawOne(from, to, -half + Math.max(0, pinch), half + Math.min(0, pinch), course * 2)
}

// One stone: a rounded shape a little irregular, sometimes with a crack in a corner
function drawLowWallStone(group, { seed, pointAt, from, to, fromDepth, toDepth, stoneIndex }) {
  const shift = (index) => (noise(seed, stoneIndex * 11 + index, 302) - 0.5) * 1.8
  const middle = from + (to - from) * (0.35 + noise(seed, stoneIndex, 306) * 0.3)
  const bulgesOutward = noise(seed, stoneIndex, 307) < 0.5
  const points = [
    pointAt(from + 0.5 + shift(0), fromDepth + 0.6 + shift(1)),
    ...(bulgesOutward ? [pointAt(middle + shift(8), fromDepth + 0.3 + shift(9) * 0.6)] : []),
    pointAt(to - 0.5 + shift(2), fromDepth + 0.6 + shift(3)),
    pointAt(to - 0.5 + shift(4), toDepth - 0.6 + shift(5)),
    ...(bulgesOutward ? [] : [pointAt(middle + shift(10), toDepth - 0.3 + shift(11) * 0.6)]),
    pointAt(from + 0.5 + shift(6), toDepth - 0.6 + shift(7))
  ]
  createSvgElement("path", { d: roundedOutline(points), fill: rock, stroke: ink, "stroke-width": 1.25,
                             "stroke-linejoin": "round" }, group)
  if (to - from <= 5 || noise(seed, stoneIndex, 303) >= 0.6) return

  const corner = pointAt(to - 1.8, toDepth - 1.8)
  const crackStart = pointAt(to - 1.8 - (to - from) * 0.35, toDepth - 1.5)
  const crackEnd = pointAt(to - 1.8, toDepth - 1.8 - (toDepth - fromDepth) * 0.3)
  createSvgElement("path", {
    d: `M${rounded(crackStart[0])} ${rounded(crackStart[1])} Q${rounded(corner[0])} ${rounded(corner[1])} ${rounded(crackEnd[0])} ${rounded(crackEnd[1])}`,
    fill: "none", stroke: ink, "stroke-width": 0.75, "stroke-linecap": "round"
  }, group)
}

// The corners of a shape cut round: each corner becomes a curve between two points close to it
function roundedOutline(points) {
  const cut = (from, to, ratio) => [from[0] + (to[0] - from[0]) * ratio, from[1] + (to[1] - from[1]) * ratio]
  return `${points.map((point, index) => {
    const previous = points[(index + points.length - 1) % points.length]
    const next = points[(index + 1) % points.length]
    const before = cut(point, previous, 0.16)
    const after = cut(point, next, 0.16)
    return `${index ? " L" : "M"}${rounded(before[0])} ${rounded(before[1])} Q${rounded(point[0])} ${rounded(point[1])} ${rounded(after[0])} ${rounded(after[1])}`
  }).join("")}Z`
}

// A door: a wooden leaf across the middle of the side, the wall it sits in on each side of it. wallStyle: the
// drawing of that wall (drawStoneWall, drawLowWall), or nothing for an ink wall
export function drawDoor(group, side, { wallStyle, seed, startEnd = straightEnd, endEnd = straightEnd }) {
  const { start, end, normalX, normalY } = side
  const pointAlong = (ratio) => [start[0] + (end[0] - start[0]) * ratio, start[1] + (end[1] - start[1]) * ratio]
  const leafStart = pointAlong(0.2)
  const leafEnd = pointAlong(0.8)
  if (wallStyle) {
    wallStyle(group, { ...side, end: leafStart }, seed, startEnd, straightEnd)
    wallStyle(group, { ...side, start: leafEnd }, seed + 1, straightEnd, endEnd)
  } else {
    drawInkWall(group, start, leafStart)
    drawInkWall(group, leafEnd, end)
  }
  const shifted = (point, depth) => [point[0] + normalX * depth, point[1] + normalY * depth]
  const halfLeaf = 2.6
  createSvgElement("path", { d: polygonPath([shifted(leafStart, halfLeaf), shifted(leafEnd, halfLeaf),
                                             shifted(leafEnd, -halfLeaf), shifted(leafStart, -halfLeaf)]),
                             fill: doorWood, stroke: ink, "stroke-width": 1.4, "stroke-linejoin": "round" }, group)
  const middle = pointAlong(0.5)
  const [hingeX1, hingeY1] = shifted(middle, halfLeaf)
  const [hingeX2, hingeY2] = shifted(middle, -halfLeaf)
  createSvgElement("line", { x1: rounded(hingeX1), y1: rounded(hingeY1), x2: rounded(hingeX2), y2: rounded(hingeY2),
                             stroke: ink, "stroke-width": 0.9 }, group)
}

function unitVector(start, end) {
  const length = Math.hypot(end[0] - start[0], end[1] - start[1])
  return [(end[0] - start[0]) / length, (end[1] - start[1]) / length]
}

function midpoint(first, second) {
  return [(first[0] + second[0]) / 2, (first[1] + second[1]) / 2]
}
