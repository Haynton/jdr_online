// A number between 0 and 1 that always comes out the same for the same three numbers: the stones of a wall, the
// strokes of a hatching vary from one place to another, but a map is drawn the same at every render
export function noise(first, second, salt) {
  let mixed = (first * 374761393 + second * 668265263 + salt * 2147483647) | 0
  mixed = Math.imul(mixed ^ (mixed >>> 13), 1274126177)
  mixed ^= mixed >>> 16
  return (mixed >>> 0) / 4294967296
}

// A small shift around 0, up to half of the amplitude on each side
export function jitter(seed, salt, amplitude = 0.8) {
  return (noise(seed, salt, 77) - 0.5) * amplitude
}
