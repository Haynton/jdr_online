// Shapes shared by the drawings of the objects (map_objects): a leafy outline, bumps of foliage, strokes of shade, a
// leaf, a soft closed outline
import { noise } from "map_editor/noise"
import { createSvgElement, rounded } from "map_editor/svg"
import { ink } from "map_editor/palette"

// A round outline of small arcs, like a bush or a tree seen from above
export function leafyOutline(centerX, centerY, radius, arcCount, seed, salt = 0) {
  const points = []
  for (let index = 0; index < arcCount; index++) {
    const angle = (index / arcCount) * Math.PI * 2 + noise(seed, index, 200 + salt) * 0.25
    const distance = radius * (0.86 + noise(seed, index, 201 + salt) * 0.16)
    points.push([centerX + Math.cos(angle) * distance, centerY + Math.sin(angle) * distance])
  }
  let path = `M${rounded(points[0][0])} ${rounded(points[0][1])}`
  for (let index = 1; index <= arcCount; index++) {
    const point = points[index % arcCount]
    const arcRadius = radius * (0.2 + noise(seed, index, 202 + salt) * 0.12)
    path += ` A${rounded(arcRadius)} ${rounded(arcRadius)} 0 0 1 ${rounded(point[0])} ${rounded(point[1])}`
  }
  return `${path}Z`
}

// Little half circles along an arc, the tufts inside a crown of leaves
export function foliageBumps(centerX, centerY, radius, fromAngle, toAngle, count, seed) {
  let path = ""
  for (let index = 0; index < count; index++) {
    const angle = fromAngle + (toAngle - fromAngle) * (index / Math.max(1, count - 1)) + (noise(seed, index, 210) - 0.5) * 0.3
    const distance = radius * (0.85 + noise(seed, index, 211) * 0.25)
    const pointX = centerX + Math.cos(angle) * distance
    const pointY = centerY + Math.sin(angle) * distance
    const bumpRadius = radius * 0.22
    path += `M${rounded(pointX - Math.sin(angle) * bumpRadius)} ${rounded(pointY + Math.cos(angle) * bumpRadius)} A${rounded(bumpRadius)} ${rounded(bumpRadius)} 0 0 0 ${rounded(pointX + Math.sin(angle) * bumpRadius)} ${rounded(pointY - Math.cos(angle) * bumpRadius)} `
  }
  return path
}

// Short diagonal strokes of shade on the lower side of a round shape
export function drawShadeStrokes(group, centerX, centerY, radius, seed, fromAngle = 0.15, toAngle = 1.5) {
  let path = ""
  for (let index = 0; index < 9; index++) {
    const angle = fromAngle + (toAngle - fromAngle) * noise(seed, index, 220)
    const distance = radius * (0.62 + noise(seed, index, 221) * 0.28)
    const pointX = centerX + Math.cos(angle) * distance
    const pointY = centerY + Math.sin(angle) * distance
    const strokeLength = 2 + noise(seed, index, 222) * 2
    path += `M${rounded(pointX - strokeLength * 0.7)} ${rounded(pointY - strokeLength * 0.7)} l${rounded(strokeLength * 1.4)} ${rounded(strokeLength * 1.4)} `
  }
  createSvgElement("path", { d: path, stroke: ink, "stroke-width": 0.7, "stroke-linecap": "round" }, group)
}

// A leaf from a point, in a direction
export function leafPath(startX, startY, angle, length, width) {
  const cosine = Math.cos(angle)
  const sine = Math.sin(angle)
  const tipX = startX + cosine * length
  const tipY = startY + sine * length
  const middleX = startX + cosine * length * 0.5
  const middleY = startY + sine * length * 0.5
  return `M${rounded(startX)} ${rounded(startY)} Q${rounded(middleX - sine * width)} ${rounded(middleY + cosine * width)} ${rounded(tipX)} ${rounded(tipY)} Q${rounded(middleX + sine * width)} ${rounded(middleY - cosine * width)} ${rounded(startX)} ${rounded(startY)}Z`
}

// A closed curve through the middles of the sides of a polygon
export function softOutline(points) {
  const last = points[points.length - 1]
  let path = ""
  points.forEach((point, index) => {
    const next = points[(index + 1) % points.length]
    const middle = [(point[0] + next[0]) / 2, (point[1] + next[1]) / 2]
    path += (index ? " Q" : `M${rounded((last[0] + point[0]) / 2)} ${rounded((last[1] + point[1]) / 2)} Q`) +
      `${rounded(point[0])} ${rounded(point[1])} ${rounded(middle[0])} ${rounded(middle[1])}`
  })
  return `${path}Z`
}

// Draws into a group: add("rect", { ... }) appends a shape to it
export function shapeAdder(group) {
  return (name, attributes) => createSvgElement(name, attributes, group)
}
