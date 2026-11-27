// The moves of a token dragged on the board (decision of 27 November): one step to one of the eight cells around,
// never into a blocked cell nor across a blocked side; a diagonal step costs 1 when both ways around its corner are
// free, 2 when it goes around the corner of a wall, and is refused when neither is. Twin of MapPassage#step_cost and
// #path_cost: changing one is changing the other. A passage of null lets every step through at a cost of 1 (the game
// master)

const diagonalCosts = { 2: 1, 1: 2 }
const stepOffsets = [-1, 0, 1].flatMap((column) => [-1, 0, 1].map((row) => [column, row]))
  .filter(([column, row]) => column !== 0 || row !== 0)

// blockedCells: [[column, row]], blockedSides: ["3,4|4,4"], as the server gives them (MapPassage)
export function passageOf(blockedCells, blockedSides) {
  return { blockedCells: new Set(blockedCells.map((cell) => cell.join(","))), blockedSides: new Set(blockedSides) }
}

export function stepCost(from, to, passage) {
  if (!passage) return 1
  if (passage.blockedCells.has(to.join(","))) return null
  if (from[0] === to[0] || from[1] === to[1]) return sideOpen(from, to, passage) ? 1 : null

  const corners = [[to[0], from[1]], [from[0], to[1]]]
  const openWays = corners.filter((corner) => wayAroundOpen(from, corner, to, passage)).length
  return diagonalCosts[openWays] ?? null
}

// The way of the token as the pointer goes: back to a cell already on it, the way stops there; further, it walks
// towards the pointer one step at a time and stops before a step refused (a wall stops the token).
// way: [{ cell: [column, row], cost }], the cost counted from the start
export function wayTowards(way, target, passage) {
  const known = way.findIndex(({ cell }) => sameCell(cell, target))
  if (known >= 0) return way.slice(0, known + 1)

  const walked = [...way]
  while (!sameCell(walked.at(-1).cell, target)) {
    const { cell, cost } = walked.at(-1)
    const next = [cell[0] + Math.sign(target[0] - cell[0]), cell[1] + Math.sign(target[1] - cell[1])]
    const step = stepCost(cell, next, passage)
    if (step === null) break

    walked.push({ cell: next, cost: cost + step })
  }
  return walked
}

// The cost of the cheapest way from a cell to another, as the server counts it (each cost a whole number: the cells
// are taken by increasing cost), null when no way leads there. size: [columns, rows]
export function pathCost(from, to, passage, size) {
  if (!passage) return Math.max(Math.abs(to[0] - from[0]), Math.abs(to[1] - from[1]))

  const bestCosts = new Map([[from.join(","), 0]])
  const cellsByCost = [[from]]
  for (let cost = 0; cost < cellsByCost.length; cost += 1) {
    for (const cell of cellsByCost[cost] ?? []) {
      if (sameCell(cell, to)) return cost
      if (bestCosts.get(cell.join(",")) === cost) reachNeighbours(cell, cost, { passage, size, bestCosts, cellsByCost })
    }
  }
  return null
}

function reachNeighbours(cell, cost, { passage, size, bestCosts, cellsByCost }) {
  stepOffsets.forEach(([columnOffset, rowOffset]) => {
    const neighbour = [cell[0] + columnOffset, cell[1] + rowOffset]
    if (!inside(neighbour, size)) return

    const step = stepCost(cell, neighbour, passage)
    if (step === null) return

    const reached = cost + step
    if ((bestCosts.get(neighbour.join(",")) ?? Infinity) <= reached) return

    bestCosts.set(neighbour.join(","), reached)
    cellsByCost[reached] ??= []
    cellsByCost[reached].push(neighbour)
  })
}

function inside([column, row], [columns, rows]) {
  return column >= 0 && row >= 0 && column < columns && row < rows
}

export function sameCell(cell, other) {
  return cell[0] === other[0] && cell[1] === other[1]
}

function wayAroundOpen(from, corner, to, passage) {
  return !passage.blockedCells.has(corner.join(",")) && sideOpen(from, corner, passage) &&
    sideOpen(corner, to, passage)
}

// Written like the edges of the layout: the two cells, sorted as texts
function sideOpen(cell, neighbour, passage) {
  return !passage.blockedSides.has([cell.join(","), neighbour.join(",")].sort().join("|"))
}
