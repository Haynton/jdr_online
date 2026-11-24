// Draws a map (its floors and its edges) into a group of the board, like the prototype: the floors filled with their
// texture, the walls that a walled floor gets on its own where it meets another floor or the empty ground, the walls
// and doors drawn by the game master, the hatching, pebbles and boulders outside, the banks of the water, the objects.
// The floors say what they do to their sides (map_floors), the edges and the objects how they are drawn (map_edges,
// map_objects)
import { floorOf, isAir } from "map_floors"
import { edgeOf, doorKey } from "map_edges"
import { objectOf, footprintSize } from "map_objects"
import { cellKey, cellPosition, cellSize, sideKey } from "map_editor/square_grid"
import { createSvgElement, polygonPath, pointKey, rounded } from "map_editor/svg"
import { noise } from "map_editor/noise"
import { drawHatching } from "map_editor/hatching"
import { drawBoulder } from "map_editor/boulder"
import { drawInkWall } from "map_editor/wall_drawing"
import { waterLoops, offsetLoop, loopPath } from "map_editor/water_outline"
import { waterPattern, glowGradient, objectShadowFilter } from "map_editor/patterns"
import { markDensity, markDepth } from "map_editor/drawing_settings"
import * as palette from "map_editor/palette"

// The floors of the border cells go on beyond the grid, so that the walls stop at the edge of the board, not before
const paddingCells = 3

export function renderMap(group, { grid, floors, edges, objects = [] }) {
  group.replaceChildren()
  const floorView = extendBeyondTheGrid(floors, grid)
  const map = { grid, edges, floorView, floorAt: (column, row) => floorOf(floorView.get(cellKey(column, row))) }
  const { borders, insides } = collectSides(map)

  // The ground goes on far around the grid: the board may be zoomed out, or wider than the map
  createSvgElement("rect", { x: -grid.width * 4, y: -grid.height * 4, width: grid.width * 9, height: grid.height * 9,
                             fill: palette.voidGround }, group)
  drawGridDots(group, grid)
  drawMarksOutside(group, map, borders)
  drawFloors(group, map)
  drawWater(group, map, insides)
  drawShadows(group, borders, insides)
  drawObjects(group, grid, objects)
  drawWalls(group, borders, insides)
  drawRocks(group, borders.filter((border) => border.floor.rocksOutside))
}

function extendBeyondTheGrid(floors, grid) {
  const floorView = new Map(floors)
  for (let column = -paddingCells; column < grid.columns + paddingCells; column++) {
    for (let row = -paddingCells; row < grid.rows + paddingCells; row++) {
      if (grid.inside(column, row)) continue

      const nearest = floors.get(cellKey(clamp(column, grid.columns), clamp(row, grid.rows)))
      if (nearest) floorView.set(cellKey(column, row), nearest)
    }
  }
  return floorView
}

function clamp(position, count) {
  return Math.min(count - 1, Math.max(0, position))
}

// Every side of a floor cell is either a border (towards the empty ground, or open air for a walled floor), or an
// inside side between two floors, seen once
function collectSides(map) {
  const borders = []
  const insides = []
  map.floorView.forEach((floorKey, key) => {
    const floor = floorOf(floorKey)
    if (!floor) return

    const [column, row] = cellPosition(key)
    map.grid.neighbours(column, row).forEach(([neighbourColumn, neighbourRow], sideIndex) => {
      const sideOfCell = { ...map.grid.side(column, row, sideIndex), column, row, sideIndex, neighbourColumn, neighbourRow }
      const neighbour = map.floorAt(neighbourColumn, neighbourRow)
      if (!neighbour || (neighbour.open && !isAir(floor))) return addBorder(map, sideOfCell, floor, borders, insides)
      if (floor.open && !isAir(neighbour)) return
      if (cellKey(neighbourColumn, neighbourRow) < key) return

      insides.push(insideSide(map, sideOfCell, floor, neighbour))
    })
  })
  return { borders, insides }
}

// A door drawn on a border is the way in: it stands in the wall of its floor
function addBorder(map, sideOfCell, floor, borders, insides) {
  if (floor.open) return

  const edgeKey = edgeKeyOf(map, sideOfCell)
  if (edgeKey === doorKey) {
    insides.push({ ...sideOfCell, edge: edgeOf(doorKey), wallStyle: edgeOf(floor.wallKey)?.drawSegment,
                   outline: Boolean(floor.wallKey), shore: false })
    return
  }
  borders.push({ ...sideOfCell, floor })
}

// Between a walled floor and another one, the side is part of the outline of the walled floor: its normal points out
// of it. Stones win over a low wall
function insideSide(map, sideOfCell, floor, neighbour) {
  const wallKeys = [floor.wallKey, neighbour.wallKey]
  const wallKey = wallKeys.includes("stone_wall") ? "stone_wall" : (floor.wallKey || neighbour.wallKey)
  const outline = Boolean(wallKey) && floor.wallKey !== neighbour.wallKey
  const side = { ...sideOfCell, edge: edgeOf(edgeKeyOf(map, sideOfCell)), wallStyle: edgeOf(wallKey)?.drawSegment,
                 outline, shore: Boolean(floor.liquid) !== Boolean(neighbour.liquid) }
  if (outline && neighbour.wallKey === wallKey) return { ...side, normalX: -side.normalX, normalY: -side.normalY }
  return side
}

function edgeKeyOf(map, { column, row, neighbourColumn, neighbourRow }) {
  return map.edges.get(sideKey([column, row], [neighbourColumn, neighbourRow]))
}

function drawGridDots(group, grid) {
  const dots = createSvgElement("g", { fill: palette.gridDot }, group)
  for (let column = 0; column <= grid.columns; column++) {
    for (let row = 0; row <= grid.rows; row++) {
      createSvgElement("circle", { cx: column * cellSize, cy: row * cellSize, r: 0.9 }, dots)
    }
  }
}

// The hatching outside the rooms, then the pebbles outside the rocky ground and the enclosures
function drawMarksOutside(group, map, borders) {
  const hasFloorAt = (column, row) => map.floorView.has(cellKey(column, row))
  const hatching = createSvgElement("g", { stroke: palette.slate, "stroke-linecap": "round", opacity: 0.85 }, group)
  drawHatching(hatching, borders.filter((border) => border.floor.inkBorder), { grid: map.grid, cellSize, hasFloorAt })

  const pebbles = createSvgElement("g", { fill: "none", stroke: palette.slate, "stroke-width": 0.9 }, group)
  borders.forEach((border) => drawPebbles(pebbles, border, hasFloorAt, map.grid))
}

function drawPebbles(group, border, hasFloorAt, grid) {
  const seed = border.column * 1291 + border.row * 37 + border.sideIndex * 7
  const pebbleCount = border.floor.pebblesOutside(markDepth)
  for (let index = 0; index < pebbleCount; index++) {
    if (noise(seed, index, 50) > 0.55 + markDensity * 0.3) continue

    const [x, y] = pointOutside(border, noise(seed, index, 51), 14 + noise(seed, index, 52) * 10 * markDepth)
    if (hasFloorAt(...grid.cellAt(x, y))) continue

    createSvgElement("ellipse", { cx: rounded(x), cy: rounded(y), rx: rounded(0.9 + noise(seed, index, 53) * 1.4),
                                  ry: rounded(0.7 + noise(seed, index, 54)) }, group)
  }
}

function pointOutside({ start, end, normalX, normalY }, ratio, distance) {
  return [start[0] + (end[0] - start[0]) * ratio + normalX * distance,
          start[1] + (end[1] - start[1]) * ratio + normalY * distance]
}

// Each texture filled in one path. Under the water, the floor of a neighbour, or deep water
function drawFloors(group, map) {
  const floorGroup = createSvgElement("g", {}, group)
  const pathsByFill = new Map()
  map.floorView.forEach((floorKey, key) => {
    const [column, row] = cellPosition(key)
    const fill = fillUnder(map, floorOf(floorKey), column, row)
    pathsByFill.set(fill, (pathsByFill.get(fill) || "") + polygonPath(map.grid.corners(column, row)))
  })
  pathsByFill.forEach((path, fill) => createSvgElement("path", { d: path, fill, stroke: fill, "stroke-width": 0.8 },
                                                       floorGroup))
  map.floorView.forEach((floorKey, key) => drawSpeckles(floorGroup, map.grid, floorOf(floorKey), cellPosition(key)))
}

function fillUnder(map, floor, column, row) {
  if (!floor) return palette.paper
  if (!floor.liquid) return floor.pattern

  const neighbour = map.grid.neighbours(column, row).map((position) => map.floorAt(...position))
    .find((candidate) => candidate && !candidate.liquid)
  return neighbour ? neighbour.pattern : waterPattern
}

// A few specks of dirt or grass on a cell, and sometimes a tuft
function drawSpeckles(group, grid, floor, [column, row]) {
  if (!floor?.speckles) return

  const [x, y] = grid.center(column, row)
  const seed = column * 733 + row * 19
  for (let index = 0; index < 2; index++) {
    createSvgElement("circle", { cx: rounded(x + (noise(seed, index, 60) - 0.5) * 16),
                                 cy: rounded(y + (noise(seed, index, 61) - 0.5) * 16), r: 0.8,
                                 fill: floor.speckles.color }, group)
  }
  if (noise(seed, 0, 62) >= floor.speckles.bladeChance) return

  const tuftX = x + (noise(seed, 1, 63) - 0.5) * 10
  const tuftY = y + (noise(seed, 2, 63) - 0.5) * 10
  createSvgElement("path", {
    d: `M${rounded(tuftX - 3)} ${rounded(tuftY)} l1.5 -4 M${rounded(tuftX)} ${rounded(tuftY)} v-5 M${rounded(tuftX + 3)} ${rounded(tuftY)} l-1.5 -4`,
    stroke: palette.grassBlade, "stroke-width": 0.9, "stroke-linecap": "round"
  }, group)
}

// The water over its cells, the faint lines between the cells of a floor, then the ripples and the banks
function drawWater(group, map, insides) {
  const waterCells = [...map.floorView].filter(([, floorKey]) => floorOf(floorKey)?.liquid)
    .map(([key]) => cellPosition(key))
  const loops = waterLoops(waterCells, map.grid, (column, row) => Boolean(map.floorAt(column, row)?.liquid))
  if (loops.length) {
    createSvgElement("path", { d: loops.map(loopPath).join(" "), fill: waterPattern, "fill-rule": "evenodd" }, group)
  }
  drawCellLines(group, insides.filter((side) => !side.edge && !side.shore))
  drawBanks(group, map.grid, waterCells, loops)
}

function drawCellLines(group, sides) {
  const lines = createSvgElement("g", { stroke: "#1a120a", "stroke-opacity": 0.16, "stroke-width": 0.6 }, group)
  sides.forEach(({ start, end }) => createSvgElement("line", {
    x1: rounded(start[0]), y1: rounded(start[1]), x2: rounded(end[0]), y2: rounded(end[1])
  }, lines))
}

function drawBanks(group, grid, waterCells, loops) {
  const banks = createSvgElement("g", { fill: "none", "stroke-linecap": "round", "stroke-linejoin": "round" }, group)
  waterCells.forEach(([column, row]) => {
    const seed = column * 733 + row * 19
    if (noise(seed, 0, 70) >= 0.55) return

    const [x, y] = grid.center(column, row)
    const waveX = x + (noise(seed, 1, 71) - 0.5) * 8
    const waveY = y + (noise(seed, 2, 71) - 0.5) * 8
    createSvgElement("path", { d: `M${rounded(waveX - 5)} ${rounded(waveY)} q2.5 -2 5 0 t5 0`, stroke: palette.shoreWave,
                               "stroke-width": 0.8, "stroke-opacity": 0.6 }, banks)
  })
  loops.forEach((points) => {
    createSvgElement("path", { d: loopPath(offsetLoop(points, 7)), stroke: palette.shoreWave, "stroke-width": 0.7,
                               "stroke-opacity": 0.55, "stroke-dasharray": "2.5 3" }, banks)
    createSvgElement("path", { d: loopPath(offsetLoop(points, 3.4)), stroke: palette.shoreWave, "stroke-width": 1.1,
                               "stroke-opacity": 0.8 }, banks)
    createSvgElement("path", { d: loopPath(points), stroke: palette.ink, "stroke-width": 1.7 }, banks)
  })
}

// A soft shadow along the walls, inside the walled floors and under the walls drawn by the game master
function drawShadows(group, borders, insides) {
  const shadows = createSvgElement("g", { stroke: palette.shadow, "stroke-opacity": 0.16, "stroke-width": 7,
                                          "stroke-linecap": "round" }, group)
  const shadowLine = ({ start, end, normalX, normalY }, inward) => createSvgElement("line", {
    x1: rounded(start[0] - normalX * inward), y1: rounded(start[1] - normalY * inward),
    x2: rounded(end[0] - normalX * inward), y2: rounded(end[1] - normalY * inward)
  }, shadows)
  borders.filter((border) => border.floor.shadowsOutside).forEach((border) => shadowLine(border, 2.5))
  insides.filter((side) => side.edge?.castsShadow).forEach((side) => shadowLine(side, 0))
}

function drawWalls(group, borders, insides) {
  const inkWalls = createSvgElement("g", {}, group)
  borders.filter((border) => border.floor.inkBorder).forEach((border) => {
    const shift = (noise(border.column, border.row, border.sideIndex) - 0.5) * 0.8
    drawInkWall(inkWalls, [border.start[0] + border.normalX * shift, border.start[1] + border.normalY * shift],
                [border.end[0] - border.normalX * shift, border.end[1] - border.normalY * shift], 2.9)
  })
  const outline = [
    ...borders.filter((border) => border.floor.wallKey).map((border) => ({ ...border, edge: edgeOf(border.floor.wallKey) })),
    ...insides.filter((side) => side.outline && side.edge?.joinsOutline)
  ]
  drawOutline(createSvgElement("g", {}, group), outline)
  drawInsideWalls(createSvgElement("g", {}, group), borders, insides, outline)
}

// The walls around a walled floor, joined on a miter where two of them meet
function drawOutline(group, outline) {
  const sidesByPoint = sidesMeetingAt(outline)
  outline.forEach((side) => side.edge.draw(group, side, {
    seed: wallSeed(side), wallStyle: side.wallStyle,
    startEnd: miterAt(side, side.start, sidesByPoint), endEnd: miterAt(side, side.end, sidesByPoint)
  }))
}

// The walls and doors drawn by the game master inside: their ends go on to meet a wall that crosses them
function drawInsideWalls(group, borders, insides, outline) {
  const walls = insides.filter((side) => side.edge && !(side.outline && side.edge.joinsOutline))
  const wallCountByPoint = new Map()
  const count = (point) => wallCountByPoint.set(pointKey(point), (wallCountByPoint.get(pointKey(point)) || 0) + 1)
  ;[...borders.filter((border) => border.floor.inkBorder), ...outline, ...insides.filter((side) => side.edge && !side.outline)]
    .forEach(({ start, end }) => { count(start); count(end) })
  const endAt = (point, thickness) => ({ extension: (wallCountByPoint.get(pointKey(point)) || 0) > 1 ? thickness / 2 : 0 })
  walls.forEach((side) => side.edge.draw(group, side, {
    seed: wallSeed(side), wallStyle: side.wallStyle,
    startEnd: endAt(side.start, side.edge.thickness), endEnd: endAt(side.end, side.edge.thickness)
  }))
}

function sidesMeetingAt(sides) {
  const sidesByPoint = new Map()
  sides.forEach((side) => [side.start, side.end].forEach((point) => {
    const key = pointKey(point)
    if (!sidesByPoint.has(key)) sidesByPoint.set(key, [])
    sidesByPoint.get(key).push(side)
  }))
  return sidesByPoint
}

// The cut where two walls of an outline meet: halfway between their normals. Straight when the wall goes on alone
function miterAt(side, point, sidesByPoint) {
  const other = (sidesByPoint.get(pointKey(point)) || []).find((candidate) => candidate !== side)
  if (!other) return { miter: [side.normalX, side.normalY] }

  const dot = side.normalX * other.normalX + side.normalY * other.normalY
  if (1 + dot < 0.2) return { miter: [side.normalX, side.normalY] }
  return { miter: [(side.normalX + other.normalX) / (1 + dot), (side.normalY + other.normalY) / (1 + dot)] }
}

function wallSeed({ column, row, sideIndex }) {
  return column * 977 + row * 31 + sideIndex
}

// Boulders piled outside the rocky ground, three per side and sometimes one further, drawn from the top down
function drawRocks(group, borders) {
  const rocks = borders.flatMap((border) => {
    const seed = border.column * 1291 + border.row * 37 + border.sideIndex * 7
    const nearRocks = [0.15, 0.5, 0.85].map((ratio, index) => {
      const [x, y] = pointOutside(border, ratio + (noise(seed, index, 40) - 0.5) * 0.2, 2 + noise(seed, index, 41) * 5)
      return { x, y, radius: 4.5 + noise(seed, index, 42) * 4, seed: seed + index }
    })
    if (markDepth <= 1 || noise(seed, 5, 43) >= 0.4 + markDensity * 0.4) return nearRocks

    const [x, y] = pointOutside(border, noise(seed, 6, 44), 10 + noise(seed, 7, 45) * 6 * (markDepth - 1))
    return [...nearRocks, { x, y, radius: 3 + noise(seed, 8, 46) * 3, seed: seed + 9 }]
  })
  const rockGroup = createSvgElement("g", {}, group)
  rocks.sort((first, second) => first.y - second.y)
    .forEach((rock) => drawBoulder(rockGroup, rock.x, rock.y, rock.radius, rock.seed))
}

// Under the walls, with a soft shadow; what blocks the way over the rest. Then the light of the fires
function drawObjects(group, grid, objects) {
  const objectGroup = createSvgElement("g", { filter: objectShadowFilter }, group)
  const lightGroup = createSvgElement("g", { "pointer-events": "none" }, group)
  const drawable = objects.filter((placedObject) => objectOf(placedObject.key))
  const drawnLast = (placedObject) => (objectOf(placedObject.key).drawnOnTop ? 1 : 0)
  drawable.sort((first, second) => drawnLast(first) - drawnLast(second)).forEach((placedObject) => {
    const mapObject = objectOf(placedObject.key)
    const [centerX, centerY] = objectCenter(placedObject, mapObject)
    drawPlacedObject(objectGroup, placedObject, mapObject, centerX, centerY)
    if (!mapObject.glow) return

    createSvgElement("circle", { cx: rounded(centerX), cy: rounded(centerY), r: rounded(mapObject.glow * cellSize),
                                 fill: glowGradient }, lightGroup)
  })
}

// The middle of the cells of an object once turned
export function objectCenter(placedObject, mapObject) {
  const [columns, rows] = footprintSize(mapObject, placedObject.rotation)
  return [(placedObject.column + columns / 2) * cellSize, (placedObject.row + rows / 2) * cellSize]
}

// Drawn around its center, then turned: its length and depth are those of the object before it is turned
export function drawPlacedObject(group, placedObject, mapObject, centerX, centerY) {
  const objectTransform = `translate(${rounded(centerX)} ${rounded(centerY)}) rotate(${placedObject.rotation * 90})`
  const seed = placedObject.column * 131 + placedObject.row * 7
  mapObject.draw(createSvgElement("g", { transform: objectTransform }, group), mapObject.width * cellSize,
                 mapObject.height * cellSize, seed)
}
