// A map played on a picture of one's own: the picture under the grid, laid by its settings (its width in cells, its
// height following its proportions, its offset from the top left corner of the grid, its opacity), then the lines of
// the cells over it, so that the game master sets the grid on the squares of the picture
import { cellSize } from "map_editor/square_grid"
import { createSvgElement, rounded } from "map_editor/svg"
import { ink, voidGround } from "map_editor/palette"

// ratio: its height over its width, known once the picture is loaded (nothing of it is drawn before)
export function renderPicture(group, { grid, url, picture, ratio }) {
  group.replaceChildren()
  createSvgElement("rect", { x: -grid.width * 4, y: -grid.height * 4, width: grid.width * 9, height: grid.height * 9,
                             fill: voidGround }, group)
  if (url && picture && ratio) drawPicture(group, url, picture, ratio)
  drawCellLines(group, grid)
}

function drawPicture(group, url, picture, ratio) {
  const width = picture.cells_wide * cellSize
  createSvgElement("image", { href: url, x: rounded(picture.offset_x), y: rounded(picture.offset_y),
                              width: rounded(width), height: rounded(width * ratio), opacity: picture.opacity,
                              preserveAspectRatio: "none" }, group)
}

// Every line of the grid, and its frame a little stronger
function drawCellLines(group, grid) {
  let path = ""
  for (let column = 0; column <= grid.columns; column++) path += `M${column * cellSize} 0 V${grid.height} `
  for (let row = 0; row <= grid.rows; row++) path += `M0 ${row * cellSize} H${grid.width} `
  createSvgElement("path", { d: path, fill: "none", stroke: ink, "stroke-width": 0.6, "stroke-opacity": 0.45,
                             "pointer-events": "none" }, group)
  createSvgElement("rect", { x: 0, y: 0, width: grid.width, height: grid.height, fill: "none", stroke: ink,
                             "stroke-width": 1.2, "stroke-opacity": 0.6, "pointer-events": "none" }, group)
}
