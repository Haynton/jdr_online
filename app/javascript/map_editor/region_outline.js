// The soft outline of a region of cells (the water, the open air): the sides between a cell of the region and one
// out of it, joined into closed loops, made irregular and rounded so that a pond or a meadow does not look like a set
// of squares. Each side has a style, chosen by sideStyleOf for the cell across it:
//   "free"     bulges in or out (water against another floor, open air against the empty ground)
//   "inward"   organic too, but only towards the inside of the region: the water never goes over the empty ground
//              (Anthony's requests: « l'eau déborde », then « c'est sensé être organique »)
//   "straight" stays exactly on the edge of its cells, corners included (open air against another floor)
// The fill and its line follow the same loop. offsetLoop draws the ripples along a loop
import { noise } from "map_editor/noise"
import { pointKey } from "map_editor/svg"

// How far an inward side and its corners come in from the edge, so that the rounded curve stays inside the cells
const inwardMargin = 2.5

export function regionLoops(cells, grid, { isInRegion, sideStyleOf = () => "free", bulge = 7 }) {
  const sides = cells.flatMap(([column, row]) => {
    const corners = grid.corners(column, row)
    return grid.neighbours(column, row)
      .map((neighbour, sideIndex) => ({ neighbour, sideIndex }))
      .filter(({ neighbour }) => !isInRegion(...neighbour))
      .map(({ neighbour, sideIndex }) => ({
        start: corners[sideIndex], end: corners[(sideIndex + 1) % corners.length], used: false,
        style: sideStyleOf(...neighbour)
      }))
  })
  return joinIntoLoops(sides).map((loop) => roughenAndSmooth(loop, bulge))
}

function joinIntoLoops(sides) {
  const sidesByStart = new Map()
  sides.forEach((side) => {
    const key = pointKey(side.start)
    if (!sidesByStart.has(key)) sidesByStart.set(key, [])
    sidesByStart.get(key).push(side)
  })
  const loops = []
  sides.forEach((firstSide) => {
    const loop = []
    let side = firstSide
    while (side && !side.used) {
      side.used = true
      loop.push(side)
      side = (sidesByStart.get(pointKey(side.end)) || []).find((candidate) => !candidate.used)
    }
    if (loop.length > 2) loops.push(loop)
  })
  return loops
}

// The points of a loop: at each corner, what its two sides call for; in the middle of each side that is not straight,
// a point moved in or out. Then three rounds of corner cutting, which never moves a held point
function roughenAndSmooth(loop, bulge) {
  let points = loop.flatMap((side, index) => {
    const previousSide = loop[(index + loop.length - 1) % loop.length]
    const corners = cornerPoints(previousSide, side)
    return side.style === "straight" ? corners : [...corners, { point: movedMiddle(side, bulge), isHeld: false }]
  })
  for (let round = 0; round < 3; round++) points = cutCorners(points)
  return points.map(({ point }) => point)
}

// A corner next to a straight side is held in place. A corner turned inward (the region on its outer side: a step,
// the edge of a hole) next to an inward side is kept, drawn in towards the region, so that the curve does not cut
// across the empty cell. Any other corner is left out: the curve rounds it off
function cornerPoints(previousSide, side) {
  if (previousSide.style === "straight" || side.style === "straight") return [{ point: side.start, isHeld: true }]
  if (!isTurnedInward(previousSide, side) || (previousSide.style !== "inward" && side.style !== "inward")) return []

  const [previousInwardX, previousInwardY] = inwardDirection(previousSide)
  const [inwardX, inwardY] = inwardDirection(side)
  return [{ point: [side.start[0] + (previousInwardX + inwardX) * inwardMargin * 1.5,
                    side.start[1] + (previousInwardY + inwardY) * inwardMargin * 1.5], isHeld: false }]
}

// The region lies on the right of a side, as the sides of its cells go round them; turning left, the corner points
// into the region
function isTurnedInward(previousSide, side) {
  const [previousAlongX, previousAlongY] = direction(previousSide)
  const [alongX, alongY] = direction(side)
  return previousAlongX * alongY - previousAlongY * alongX < 0
}

// A free side moves in or out at its middle; an inward side comes in by the margin, and a little more here and there
function movedMiddle(side, bulge) {
  const middle = [(side.start[0] + side.end[0]) / 2, (side.start[1] + side.end[1]) / 2]
  const randomness = noise(Math.round(middle[0] * 10), Math.round(middle[1] * 10), 90)
  const shift = side.style === "inward" ? inwardMargin + randomness * (bulge / 2) : (randomness - 0.5) * bulge
  const [inwardX, inwardY] = inwardDirection(side)
  return [middle[0] + inwardX * shift, middle[1] + inwardY * shift]
}

function direction({ start, end }) {
  const length = Math.hypot(end[0] - start[0], end[1] - start[1])
  return [(end[0] - start[0]) / length, (end[1] - start[1]) / length]
}

// Towards the region: on the right of the side
function inwardDirection(side) {
  const [alongX, alongY] = direction(side)
  return [-alongY, alongX]
}

// Each side replaced by its points at a quarter and three quarters; a held point stays itself instead, so that a
// straight run between two held points stays straight
function cutCorners(points) {
  return points.flatMap((current, index) => {
    const next = points[(index + 1) % points.length]
    const cutPoints = []
    if (current.isHeld) cutPoints.push(current)
    else cutPoints.push({ point: between(current.point, next.point, 0.25), isHeld: false })
    if (!next.isHeld) cutPoints.push({ point: between(current.point, next.point, 0.75), isHeld: false })
    return cutPoints
  })
}

function between(from, to, ratio) {
  return [from[0] + (to[0] - from[0]) * ratio, from[1] + (to[1] - from[1]) * ratio]
}

export function offsetLoop(points, distance) {
  return points.map((point, index) => {
    const previous = points[(index + points.length - 1) % points.length]
    const next = points[(index + 1) % points.length]
    const alongX = next[0] - previous[0]
    const alongY = next[1] - previous[1]
    const length = Math.hypot(alongX, alongY) || 1
    return [point[0] - (alongY / length) * distance, point[1] + (alongX / length) * distance]
  })
}

export function loopPath(points) {
  return `M${points.map(([x, y]) => `${x.toFixed(1)} ${y.toFixed(1)}`).join(" L")}Z`
}
