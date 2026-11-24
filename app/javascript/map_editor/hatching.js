// The hatching around the walls of the rooms, on the empty ground outside them, like a map drawn by hand: small
// clusters of parallel strokes, dense near the wall and fading away from it. Nothing is hatched over a floor
import { noise } from "map_editor/noise"
import { createSvgElement, rounded } from "map_editor/svg"
import { markDensity as density, markDepth } from "map_editor/drawing_settings"

export function drawHatching(group, sides, { grid, cellSize, hasFloorAt }) {
  if (!sides.length) return

  const spacing = 10.5 - density * 4
  const reach = (markDepth + 1) * cellSize * 0.36
  const margin = reach * 1.25
  for (let gridX = -margin; gridX < grid.width + margin; gridX += spacing) {
    for (let gridY = -margin; gridY < grid.height + margin; gridY += spacing) {
      hatchAround({ group, sides, grid, hasFloorAt, spacing, reach, gridX, gridY })
    }
  }
}

function hatchAround({ group, sides, grid, hasFloorAt, spacing, reach, gridX, gridY }) {
  const indexX = Math.round(gridX / spacing)
  const indexY = Math.round(gridY / spacing)
  const x = gridX + (noise(indexX, indexY, 16) - 0.5) * 5
  const y = gridY + (noise(indexX, indexY, 17) - 0.5) * 5
  if (hasFloorAt(...grid.cellAt(x, y))) return

  const { distance, towardX, towardY } = closestSide([x, y], sides)
  const localReach = reach * (0.88 + noise(indexX, indexY, 11) * 0.24)
  if (distance > localReach) return

  const progress = distance / localReach
  const chance = (progress < 0.75 ? 1 : 1 - (progress - 0.75) * 2.4) * (0.3 + density * 0.7)
  if (noise(indexX, indexY, 12) > chance) return

  const facesTheWall = progress < 0.3 && noise(indexX, indexY, 13) < 0.6
  const angle = facesTheWall
    ? Math.atan2(towardY, towardX) + (noise(indexX, indexY, 14) - 0.5) * 0.7
    : noise(indexX, indexY, 15) * Math.PI
  drawCluster(group, x, y, 6.5 + noise(indexX, indexY, 18) * 1.5, angle, indexX * 92821 + indexY * 68917)
}

function closestSide([x, y], sides) {
  return sides.reduce((closest, { start, end }) => {
    const alongX = end[0] - start[0]
    const alongY = end[1] - start[1]
    const progress = Math.max(0, Math.min(1, ((x - start[0]) * alongX + (y - start[1]) * alongY) /
                                             (alongX * alongX + alongY * alongY)))
    const pointX = start[0] + alongX * progress
    const pointY = start[1] + alongY * progress
    const distance = Math.hypot(x - pointX, y - pointY)
    return distance < closest.distance ? { distance, towardX: pointX - x, towardY: pointY - y } : closest
  }, { distance: Infinity, towardX: 0, towardY: 0 })
}

// A few parallel strokes of varying length
export function drawCluster(group, centerX, centerY, size, angle, seed) {
  const strokeCount = 4 + Math.floor(noise(seed, 1, 2) * 3)
  const gap = 1.9
  const cosine = Math.cos(angle)
  const sine = Math.sin(angle)
  const cluster = createSvgElement("g", { "stroke-width": (0.5 + noise(seed, 3, 4) * 0.2).toFixed(2) }, group)
  for (let index = 0; index < strokeCount; index++) {
    const offset = (index - (strokeCount - 1) / 2) * gap
    const half = (size / 2) * (0.55 + noise(seed, index, 5) * 0.6)
    const shift = (noise(seed, index, 6) - 0.5) * 2.2
    const middleX = centerX - sine * offset + cosine * shift
    const middleY = centerY + cosine * offset + sine * shift
    createSvgElement("line", { x1: rounded(middleX - cosine * half), y1: rounded(middleY - sine * half),
                               x2: rounded(middleX + cosine * half), y2: rounded(middleY + sine * half) }, cluster)
  }
}
