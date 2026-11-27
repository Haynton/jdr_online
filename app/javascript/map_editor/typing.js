export function isTyping(event) {
  return Boolean(event.target.closest?.("input, textarea, select, [contenteditable]"))
}
