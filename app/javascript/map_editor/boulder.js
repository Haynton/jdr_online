// A boulder seen from above: a rounded, irregular stone, with a few strokes of shade and sometimes a crack
import { ink, rock } from "map_editor/palette"
import { noise } from "map_editor/noise"
import { createSvgElement, rounded } from "map_editor/svg"

const pointCount = 9

export function drawBoulder(group, centerX, centerY, radius, seed) {
  const points = []
  for (let index = 0; index < pointCount; index++) {
    const angle = (index / pointCount) * Math.PI * 2 + noise(seed, index, 30) * 0.3
    const distance = radius * (0.78 + noise(seed, index, 31) * 0.4)
    points.push([centerX + Math.cos(angle) * distance, centerY + Math.sin(angle) * distance * 0.85])
  }
  createSvgElement("path", { d: smoothOutline(points), fill: rock, stroke: ink, "stroke-width": radius > 5 ? 1.6 : 1.2,
                             "stroke-linejoin": "round" }, group)
  drawShade(group, centerX, centerY, radius, seed)
  if (radius > 6 && noise(seed, 9, 33) < 0.5) drawCrack(group, centerX, centerY, radius)
}

// A closed curve through the middles of the sides, the points as its controls
export function smoothOutline(points) {
  const last = points[points.length - 1]
  let path = `M${rounded((last[0] + points[0][0]) / 2)} ${rounded((last[1] + points[0][1]) / 2)}`
  points.forEach((point, index) => {
    const next = points[(index + 1) % points.length]
    path += ` Q${rounded(point[0])} ${rounded(point[1])} ${rounded((point[0] + next[0]) / 2)} ${rounded((point[1] + next[1]) / 2)}`
  })
  return `${path}Z`
}

function drawShade(group, centerX, centerY, radius, seed) {
  const strokeCount = Math.max(2, Math.round(radius / 2.5))
  let strokes = ""
  for (let index = 0; index < strokeCount; index++) {
    const angle = 0.35 + index * 0.32 + noise(seed, index, 32) * 0.15
    const inner = radius * 0.45
    const outer = radius * 0.82
    strokes += `M${rounded(centerX + Math.cos(angle) * inner)} ${rounded(centerY + Math.sin(angle) * inner * 0.85)} L${rounded(centerX + Math.cos(angle) * outer)} ${rounded(centerY + Math.sin(angle) * outer * 0.85)} `
  }
  createSvgElement("path", { d: strokes, stroke: ink, "stroke-width": 0.8, "stroke-linecap": "round" }, group)
}

function drawCrack(group, centerX, centerY, radius) {
  createSvgElement("path", {
    d: `M${rounded(centerX - radius * 0.4)} ${rounded(centerY - radius * 0.2)} l${rounded(radius * 0.3)} ${rounded(radius * 0.15)} l${rounded(radius * 0.15)} ${rounded(-radius * 0.3)}`,
    stroke: ink, "stroke-width": 0.8, fill: "none", "stroke-linecap": "round"
  }, group)
}
