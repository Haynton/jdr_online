// The banks of the water: the sides between a water cell and any other one, joined into closed loops, then made
// irregular and smoothed, so that a pond does not look like a set of squares. offsetLoop draws the ripples along them
import { noise } from "map_editor/noise"
import { pointKey } from "map_editor/svg"

export function waterLoops(waterCells, grid, isWaterAt) {
  const sides = waterCells.flatMap(([column, row]) => {
    const corners = grid.corners(column, row)
    return grid.neighbours(column, row)
      .map((neighbour, sideIndex) => ({ neighbour, sideIndex }))
      .filter(({ neighbour }) => !isWaterAt(...neighbour))
      .map(({ sideIndex }) => ({ start: corners[sideIndex], end: corners[(sideIndex + 1) % corners.length], used: false }))
  })
  return joinIntoLoops(sides).map(roughenAndSmooth)
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
    const points = []
    let side = firstSide
    while (side && !side.used) {
      side.used = true
      points.push(side.start)
      side = (sidesByStart.get(pointKey(side.end)) || []).find((candidate) => !candidate.used)
    }
    if (points.length > 2) loops.push(points)
  })
  return loops
}

// Each side moved a little in or out at its middle, then three rounds of corner cutting
function roughenAndSmooth(points) {
  let loop = points.map((point, index) => {
    const next = points[(index + 1) % points.length]
    const middle = [(point[0] + next[0]) / 2, (point[1] + next[1]) / 2]
    const alongX = next[0] - point[0]
    const alongY = next[1] - point[1]
    const length = Math.hypot(alongX, alongY)
    const bulge = (noise(Math.round(middle[0] * 10), Math.round(middle[1] * 10), 90) - 0.5) * 7
    return [middle[0] - (alongY / length) * bulge, middle[1] + (alongX / length) * bulge]
  })
  for (let round = 0; round < 3; round++) loop = cutCorners(loop)
  return loop
}

function cutCorners(loop) {
  return loop.flatMap((point, index) => {
    const next = loop[(index + 1) % loop.length]
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
