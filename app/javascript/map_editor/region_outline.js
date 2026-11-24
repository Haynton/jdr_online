// The soft outline of a region of cells (the water, the open air): the sides between a cell of the region and one
// out of it, joined into closed loops, then made irregular and smoothed, so that a pond or a meadow does not look like
// a set of squares. Only the sides that isRoughSide chooses bulge in or out (all of them for water, only those that
// face the empty ground for open air); the others stay on their line. offsetLoop draws the ripples along a loop
import { noise } from "map_editor/noise"
import { pointKey } from "map_editor/svg"

export function regionLoops(cells, grid, { isInRegion, isRoughSide = () => true, bulge = 7 }) {
  const sides = cells.flatMap(([column, row]) => {
    const corners = grid.corners(column, row)
    return grid.neighbours(column, row)
      .map((neighbour, sideIndex) => ({ neighbour, sideIndex }))
      .filter(({ neighbour }) => !isInRegion(...neighbour))
      .map(({ neighbour, sideIndex }) => ({
        start: corners[sideIndex], end: corners[(sideIndex + 1) % corners.length], used: false,
        rough: isRoughSide(...neighbour)
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

// Each rough side moved a little in or out at its middle, then three rounds of corner cutting
function roughenAndSmooth(loop, bulge) {
  let points = loop.map(({ start, end, rough }) => {
    const middle = [(start[0] + end[0]) / 2, (start[1] + end[1]) / 2]
    if (!rough) return middle

    const alongX = end[0] - start[0]
    const alongY = end[1] - start[1]
    const length = Math.hypot(alongX, alongY)
    const shift = (noise(Math.round(middle[0] * 10), Math.round(middle[1] * 10), 90) - 0.5) * bulge
    return [middle[0] - (alongY / length) * shift, middle[1] + (alongX / length) * shift]
  })
  for (let round = 0; round < 3; round++) points = cutCorners(points)
  return points
}

function cutCorners(points) {
  return points.flatMap((point, index) => {
    const next = points[(index + 1) % points.length]
    return [[point[0] * 0.75 + next[0] * 0.25, point[1] * 0.75 + next[1] * 0.25],
            [point[0] * 0.25 + next[0] * 0.75, point[1] * 0.25 + next[1] * 0.75]]
  })
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
