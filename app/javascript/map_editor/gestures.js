const pixelsPerWheelLine = 40

// A touchpad slides in pixels, often sideways too, and Chrome and Safari give it a wheelDeltaY of exactly -3 times its
// deltaY; a mouse wheel turns by lines (Firefox) or by notches that do not follow that rule. Firefox gives no
// wheelDeltaY: in pixels there, it is a touchpad
export function isTouchpadSlide(event) {
  if (event.deltaMode === WheelEvent.DOM_DELTA_LINE) return false
  if (event.deltaX !== 0) return true
  if (event.wheelDeltaY === undefined) return true

  return event.wheelDeltaY === -3 * event.deltaY
}

// How far the wheel turned, in pixels: Firefox counts a mouse wheel in lines (about 3 a notch), which hardly zoomed
export function wheelPixels(event) {
  return event.deltaMode === WheelEvent.DOM_DELTA_LINE ? event.deltaY * pixelsPerWheelLine : event.deltaY
}

export function pinchShape(activePointers) {
  const [first, second] = [...activePointers.values()]
  return { distance: Math.hypot(second[0] - first[0], second[1] - first[1]) || 1,
           middle: [(first[0] + second[0]) / 2, (first[1] + second[1]) / 2] }
}
