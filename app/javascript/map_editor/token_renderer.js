// The tokens of the non-player characters and enemies of a table on its map, drawn over everything in the editor: a
// round counter in the color of its role (an enemy in red, a non-player character in green), the first letters of its
// name, and its number when the same character has several tokens on the map (a band: « Gobelin 2 »)
import { cellSize } from "map_editor/square_grid"
import { createSvgElement } from "map_editor/svg"
import { enemyToken, npcToken, playerToken, ink, tokenLetters, allowedMark } from "map_editor/palette"

const tokenRadius = cellSize * 0.4
const hiddenTokenOpacity = 0.5
let picturesDrawn = 0

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
    const centerX = (token.column + 0.5) * cellSize
    const centerY = (token.row + 0.5) * cellSize
    const startsHidden = token.hidden !== false
    drawToken(createSvgElement("g", { opacity: startsHidden ? hiddenTokenOpacity : 1 }, layer), centerX, centerY,
              character, number)
    if (startsHidden) drawHiddenMark(layer, centerX - tokenRadius * 0.75, centerY + tokenRadius * 0.75)
  })
}

export function renderBoardTokens(layer, tokens) {
  layer.replaceChildren()
  tokens.forEach((token) => {
    const tokenGroup = createSvgElement("g", { "data-board-token-id": token.id, "data-hidden": token.hidden,
                                               "data-name": token.name, "data-kind": token.kind,
                                               "data-custom-name": token.custom_name ?? "",
                                               "data-character-name": token.character_name ?? "" }, layer)
    const centerX = (token.column + 0.5) * cellSize
    const centerY = (token.row + 0.5) * cellSize
    const drawing = createSvgElement("g", { opacity: token.hidden ? hiddenTokenOpacity : 1 }, tokenGroup)
    drawToken(drawing, centerX, centerY, token, token.number)
    if (token.hidden) drawHiddenMark(tokenGroup, centerX - tokenRadius * 0.75, centerY + tokenRadius * 0.75)
    if (token.letter) drawLetter(tokenGroup, centerX - tokenRadius * 0.75, centerY - tokenRadius * 0.75, token.letter)
  })
}

function drawLetter(group, centerX, centerY, letter) {
  createSvgElement("circle", { cx: centerX, cy: centerY, r: 4.2, fill: allowedMark, stroke: tokenLetters,
                               "stroke-width": 0.8 }, group)
  const label = createSvgElement("text", { x: centerX, y: centerY, "text-anchor": "middle", "dominant-baseline": "central",
                                           fill: tokenLetters, "font-size": letter.length > 1 ? 4 : 5.5,
                                           "font-weight": 700, "font-family": "Inter, sans-serif" }, group)
  label.textContent = letter
}

export function drawHiddenMark(group, centerX, centerY) {
  createSvgElement("circle", { cx: centerX, cy: centerY, r: 4.2, fill: ink, stroke: tokenLetters, "stroke-width": 0.8 },
                   group)
  createSvgElement("ellipse", { cx: centerX, cy: centerY, rx: 2.4, ry: 1.4, fill: "none", stroke: tokenLetters,
                                "stroke-width": 0.7 }, group)
  createSvgElement("line", { x1: centerX - 2.4, y1: centerY + 2.2, x2: centerX + 2.4, y2: centerY - 2.2,
                             stroke: tokenLetters, "stroke-width": 0.8, "stroke-linecap": "round" }, group)
}

export function drawToken(group, centerX, centerY, { name, kind, picture }, number = null) {
  createSvgElement("circle", { cx: centerX, cy: centerY + 1, r: tokenRadius, fill: ink, opacity: 0.25 }, group)
  createSvgElement("circle", { cx: centerX, cy: centerY, r: tokenRadius, fill: tokenColorOf(kind) }, group)
  if (picture) {
    picturesDrawn += 1
    drawPicture(group, centerX, centerY, picture, `token-picture-${picturesDrawn}`)
  } else {
    const letters = createSvgElement("text", { x: centerX, y: centerY, "text-anchor": "middle",
                                               "dominant-baseline": "central", fill: tokenLetters, "font-size": 8,
                                               "font-weight": 700, "font-family": "Inter, sans-serif" }, group)
    letters.textContent = initialsOf(name)
  }
  createSvgElement("circle", { cx: centerX, cy: centerY, r: tokenRadius, fill: "none", stroke: tokenLetters,
                               "stroke-width": 1.4 }, group)
  if (number) drawNumber(group, centerX + tokenRadius * 0.75, centerY - tokenRadius * 0.75, number)
}

function tokenColorOf(kind) {
  if (kind === "monster") return enemyToken
  return kind === "pc" ? playerToken : npcToken
}

function drawPicture(group, centerX, centerY, url, clipId) {
  const clip = createSvgElement("clipPath", { id: clipId }, group)
  createSvgElement("circle", { cx: centerX, cy: centerY, r: tokenRadius }, clip)
  createSvgElement("image", { href: url, x: centerX - tokenRadius, y: centerY - tokenRadius, width: tokenRadius * 2,
                              height: tokenRadius * 2, preserveAspectRatio: "xMidYMid slice",
                              "clip-path": `url(#${clipId})` }, group)
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
