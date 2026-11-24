// What the game master can undo and redo in the editor: the drawing as it was before each change (a stroke, clearing
// everything), 200 at most, like the prototype. Lost when the page is left: the saved drawing is the last one
const largestHistory = 200

export default class DrawingHistory {
  constructor() {
    this.undoable = []
    this.redoable = []
  }

  // before: the snapshot of the drawing before the change
  record(before) {
    this.undoable.push(before)
    if (this.undoable.length > largestHistory) this.undoable.shift()
    this.redoable = []
  }

  // The snapshot to go back to, current: the drawing as it is now, to redo it later
  undo(current) {
    if (!this.canUndo()) return null

    this.redoable.push(current)
    return this.undoable.pop()
  }

  redo(current) {
    if (!this.canRedo()) return null

    this.undoable.push(current)
    return this.redoable.pop()
  }

  canUndo() {
    return this.undoable.length > 0
  }

  canRedo() {
    return this.redoable.length > 0
  }
}
