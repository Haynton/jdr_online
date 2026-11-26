import { Controller } from "@hotwired/stimulus"
import SquareGrid from "map_editor/square_grid"
import { renderMap } from "map_editor/map_renderer"
import { renderPicture } from "map_editor/picture_renderer"
import { addMapPatterns } from "map_editor/patterns"
import { createSvgElement } from "map_editor/svg"
import { voidGround } from "map_editor/palette"
import { renderBlockedCells, renderNaturalBlocks } from "map_editor/blocked_renderer"
import { naturalBlocks } from "map_editor/passage"
import { renderTokens } from "map_editor/token_renderer"

// The preview of a map on its card of « Mes cartes » (Anthony's request): its drawing, drawn like in the editor, or
// its picture under its grid. A map of a table shows its blocked zones and its tokens over it (tokenCharacters: who
// they are). The textures of the floors are added once to the page, shared by every preview. The map shown on the
// board of the game room takes the tokens put on it (placeToken)
export default class extends Controller {
  static values = { layout: Object, columns: Number, rows: Number, pictureUrl: String, tokenCharacters: Object,
                    showNaturalBlocks: Boolean }

  connect() {
    addSharedPatternsOnce()
    this.element.style.backgroundColor = voidGround
    this.grid = new SquareGrid(this.columnsValue, this.rowsValue)
    this.drawing = createSvgElement("g", {}, this.element)
    if (this.layoutValue.mode === "picture") return this.drawPicture()

    const floors = new Map(Object.entries(this.layoutValue.floors))
    const edges = new Map(Object.entries(this.layoutValue.edges))
    renderMap(this.drawing, { grid: this.grid, floors, edges, objects: this.layoutValue.objects || [] })
    if (this.showNaturalBlocksValue) {
      renderNaturalBlocks(this.drawing, this.grid, naturalBlocks({ grid: this.grid, floors, edges }))
    }
    this.drawWhatIsPut()
  }

  drawWhatIsPut() {
    renderBlockedCells(this.drawing, new Set(this.layoutValue.blocked || []))
    this.tokensLayer = createSvgElement("g", {}, this.drawing)
    renderTokens(this.tokensLayer, this.layoutValue.tokens || [], this.tokenCharactersValue)
  }

  // A token put on the map shown on the board of the game room (room_board_controller.js), one per cell; nothing is
  // saved yet (the board comes with its own branch). False when the cell already holds one
  placeToken({ id, name, kind }, column, row) {
    const tokens = this.layoutValue.tokens || []
    if (tokens.some((token) => token.column === column && token.row === row)) return false

    this.tokenCharactersValue = { ...this.tokenCharactersValue, [id]: { name, kind } }
    this.layoutValue = { ...this.layoutValue, tokens: [...tokens, { character_id: id, column, row }] }
    this.tokensLayer.replaceChildren()
    renderTokens(this.tokensLayer, this.layoutValue.tokens, this.tokenCharactersValue)
    return true
  }

  // Its proportions known once it is loaded
  drawPicture() {
    const picture = new Image()
    picture.addEventListener("load", () => {
      renderPicture(this.drawing, { grid: this.grid, url: this.pictureUrlValue, picture: this.layoutValue.picture,
                                    ratio: picture.naturalHeight / picture.naturalWidth })
      this.drawWhatIsPut()
    })
    picture.src = this.pictureUrlValue
  }
}

function addSharedPatternsOnce() {
  if (document.getElementById("map-pattern-wood")) return

  const patternsHolder = createSvgElement("svg", { id: "map-patterns", width: 0, height: 0, "aria-hidden": "true",
                                                   style: "position: absolute", "data-turbo-permanent": "" },
                                          document.body)
  addMapPatterns(patternsHolder)
}
