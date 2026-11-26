import { Controller } from "@hotwired/stimulus"

// The feed of the chat of the game room (game_rooms/_chat). A line comes from the page or live from the channel, the
// same for everyone: here each reader sees their own lines marked (data-own), a message that follows one of the same
// author by less than five minutes without its header again (data-continued), and the time in their own time zone.
// The feed follows its newest line while the reader is at its bottom (or wrote it), and stays where it is while they
// read further up. The field grows with its text; Enter sends, Shift + Enter goes to the line; a message sent, the
// field is emptied and keeps the focus
const BOTTOM_MARGIN = 48
const CONTINUED_WITHIN_MS = 5 * 60 * 1000

export default class extends Controller {
  static targets = ["scroller", "line", "time", "form", "field"]
  static values = { currentUserId: String }

  connect() {
    this.scrollToBottom()
  }

  lineTargetConnected(line) {
    const own = Boolean(line.dataset.authorId) && line.dataset.authorId === this.currentUserIdValue
    line.toggleAttribute("data-own", own)
    line.toggleAttribute("data-continued", this.continuesPrevious(line))
    if (own || this.nearBottom) this.scrollToBottom()
  }

  timeTargetConnected(time) {
    const shownTime = new Date(time.getAttribute("datetime"))
    time.textContent = shownTime.toLocaleTimeString(document.documentElement.lang, { hour: "2-digit", minute: "2-digit" })
  }

  // The answer of the server replaces the form (empty, or with its error): the new field takes the focus back
  fieldTargetConnected(field) {
    this.fitField({ target: field })
    if (this.focusAfterSend) field.focus()
    this.focusAfterSend = false
  }

  sent() {
    this.focusAfterSend = true
  }

  // Not while a word is being composed (an accent, a Japanese input): Enter then chooses the word
  sendOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    if (event.target.value.trim() !== "") this.formTarget.requestSubmit()
  }

  // As high as its text, up to its maximum height (max-h-32): beyond, it scrolls
  fitField({ target: field }) {
    field.style.height = "auto"
    field.style.height = `${field.scrollHeight + field.offsetHeight - field.clientHeight}px`
  }

  continuesPrevious(line) {
    const previous = line.previousElementSibling
    if (!previous || previous.dataset.kind !== "message" || line.dataset.kind !== "message") return false
    if (!line.dataset.authorId || previous.dataset.authorId !== line.dataset.authorId) return false

    return new Date(line.dataset.createdAt) - new Date(previous.dataset.createdAt) < CONTINUED_WITHIN_MS
  }

  get nearBottom() {
    if (!this.hasScrollerTarget) return true

    const { scrollHeight, scrollTop, clientHeight } = this.scrollerTarget
    return scrollHeight - scrollTop - clientHeight < BOTTOM_MARGIN
  }

  scrollToBottom() {
    if (this.hasScrollerTarget) this.scrollerTarget.scrollTop = this.scrollerTarget.scrollHeight
  }
}
