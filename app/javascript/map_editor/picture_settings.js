// How the picture of a map sits under its grid (the key "picture" of its layout, checked by MapLayouts::PictureCheck):
// its width in cells, its offset from the top left corner of the grid (in units of the map), its opacity. The same
// bounds as the server
import { cellSize } from "map_editor/square_grid"

const fewestCellsWide = 1
const mostCellsWide = 200
const lowestOpacity = 0.1

// As wide as the grid, from its top left corner, fully seen
export function defaultPicture(grid) {
  return { cells_wide: grid.columns, offset_x: 0, offset_y: 0, opacity: 1 }
}

export function withCellsWide(picture, cellsWide) {
  const bounded = Math.min(mostCellsWide, Math.max(fewestCellsWide, Math.round(cellsWide) || picture.cells_wide))
  return { ...picture, cells_wide: bounded }
}

// The middle of the picture on the middle of the grid (ratio: its height over its width)
export function centered(picture, grid, ratio) {
  const width = picture.cells_wide * cellSize
  return { ...picture, offset_x: Math.round((grid.width - width) / 2),
           offset_y: Math.round((grid.height - width * ratio) / 2) }
}

// What each slider of the tab Image changes, its bounds for this grid, and how its value reads in the layout
export const sliders = {
  offset_x: { bounds: (grid) => [-grid.width, grid.width], fromSlider: (value) => value, toSlider: (value) => value },
  offset_y: { bounds: (grid) => [-grid.height, grid.height], fromSlider: (value) => value, toSlider: (value) => value },
  opacity: { bounds: () => [lowestOpacity * 100, 100], fromSlider: (value) => value / 100,
             toSlider: (value) => Math.round(value * 100) }
}
