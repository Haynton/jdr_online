// Small helpers to build the SVG of a map
const svgNamespace = "http://www.w3.org/2000/svg"

export function createSvgElement(name, attributes = {}, parent = null) {
  const element = document.createElementNS(svgNamespace, name)
  Object.entries(attributes).forEach(([attribute, value]) => element.setAttribute(attribute, value))
  if (parent) parent.appendChild(element)
  return element
}

// One decimal is enough for a drawing, and keeps the SVG short
export function rounded(number) {
  return number.toFixed(1)
}

// A closed shape through points [[x, y], ...]
export function polygonPath(points) {
  return `M${points.map(([x, y]) => `${rounded(x)} ${rounded(y)}`).join(" L")}Z`
}

export function pointKey([x, y]) {
  return `${rounded(x)},${rounded(y)}`
}
