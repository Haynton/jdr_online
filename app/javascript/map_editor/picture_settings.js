// How the picture of a map sits under its grid (the key "picture" of its layout, checked by MapLayouts::PictureCheck):
// its width in cells, its offset from the top left corner of the grid (in units of the map), its opacity. The same
// bounds as the server. The editor lays it over the whole grid (fittedPicture): the grid follows the picture, only
// the number of cells across is chosen
const lowestOpacity = 0.1

// As wide as the grid, from its top left corner, fully seen
export function defaultPicture(grid) {
  return { cells_wide: grid.columns, offset_x: 0, offset_y: 0, opacity: 1 }
}

// As wide as a grid of that many columns, from its top left corner, its opacity kept
export function fittedPicture(picture, columns) {
  return { cells_wide: columns, offset_x: 0, offset_y: 0, opacity: picture?.opacity ?? 1 }
}

export function isFitted(picture, columns) {
  return picture?.cells_wide === columns && picture.offset_x === 0 && picture.offset_y === 0
}

// The rows of a grid laid over a picture of that ratio (its height over its width): rounded down, so that no cell
// falls outside the picture (what is left at its bottom, less than a cell, is cut)
export function rowsOverPicture(columns, ratio) {
  return Math.floor(columns * ratio)
}

// What each slider of the tab Image changes, its bounds, and how its value reads in the layout
export const sliders = {
  opacity: { bounds: () => [lowestOpacity * 100, 100], fromSlider: (value) => value / 100,
             toSlider: (value) => Math.round(value * 100) }
}
