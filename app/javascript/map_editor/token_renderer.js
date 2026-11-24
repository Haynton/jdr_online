// The tokens of the non-player characters and enemies of a table on its map, drawn over everything in the editor: a
// round counter in the color of its role (an enemy in red, a non-player character in green), the first letters of its
// name, and its number when the same character has several tokens on the map (a band: « Gobelin 2 »)
import { cellSize } from "map_editor/square_grid"
import { createSvgElement } from "map_editor/svg"
import { enemyToken, npcToken, ink, tokenLetters } from "map_editor/palette"

const tokenRadius = cellSize * 0.4

// characters: { id: { name, kind } }, from the page
export function renderTokens(group, tokens, characters) {
  if (tokens.length === 0) return

  const layer = createSvgElement("g", { "pointer-events": "none" }, group)
  const countByCharacter = new Map()
  tokens.forEach((token) => countByCharacter.set(token.character_id, (countByCharacter.get(token.character_id) ?? 0) + 1))
  const numbers = new Map()
  tokens.forEach((token) => {
    const character = characters[token.character_id]
    if (!character) return

    numbers.set(token.character_id, (numbers.get(token.character_id) ?? 0) + 1)
    const number = countByCharacter.get(token.character_id) > 1 ? numbers.get(token.character_id) : null
    drawToken(layer, (token.column + 0.5) * cellSize, (token.row + 0.5) * cellSize, character, number)
  })
}

export function drawToken(group, centerX, centerY, { name, kind }, number = null) {
  createSvgElement("circle", { cx: centerX, cy: centerY + 1, r: tokenRadius, fill: ink, opacity: 0.25 }, group)
  createSvgElement("circle", { cx: centerX, cy: centerY, r: tokenRadius, fill: kind === "monster" ? enemyToken : npcToken,
                               stroke: tokenLetters, "stroke-width": 1.4 }, group)
  const letters = createSvgElement("text", { x: centerX, y: centerY, "text-anchor": "middle", "dominant-baseline": "central",
                                             fill: tokenLetters, "font-size": 8, "font-weight": 700,
                                             "font-family": "Inter, sans-serif" }, group)
  letters.textContent = initialsOf(name)
  if (number) drawNumber(group, centerX + tokenRadius * 0.75, centerY - tokenRadius * 0.75, number)
}

function drawNumber(group, centerX, centerY, number) {
  createSvgElement("circle", { cx: centerX, cy: centerY, r: 4.2, fill: tokenLetters, stroke: ink, "stroke-width": 0.8 },
                   group)
  const label = createSvgElement("text", { x: centerX, y: centerY, "text-anchor": "middle", "dominant-baseline": "central",
                                           fill: ink, "font-size": 5.5, "font-weight": 700,
                                           "font-family": "Inter, sans-serif" }, group)
  label.textContent = number
}

// « Guerrier gobelin » gives « GG », « Aubergiste » « AU »
function initialsOf(name) {
  const words = name.trim().split(/\s+/).filter(Boolean)
  if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase()

  return (words[0] ?? "?").slice(0, 2).toUpperCase()
}
