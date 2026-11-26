import { Controller } from "@hotwired/stimulus"

// The feed of the chat of the game room (game_rooms/_chat). A line comes from the page or live from the channel, the
// same for everyone: here each reader sees their own lines marked (data-own) and the time in their own time zone.
// The feed follows its newest line while the reader is at its bottom (or wrote it), and stays where it is while
// they read further up. A message sent, the field is emptied and keeps the focus
const BOTTOM_MARGIN = 48

export default class extends Controller {
  static targets = ["scroller", "line", "time", "form", "field"]
  static values = { currentUserId: String }

  connect() {
    this.scrollToBottom()
  }

  lineTargetConnected(line) {
    const own = line.dataset.authorId === this.currentUserIdValue
    line.toggleAttribute("data-own", own)
    if (own || this.nearBottom) this.scrollToBottom()
  }

  timeTargetConnected(time) {
    const shownTime = new Date(time.getAttribute("datetime"))
    time.textContent = shownTime.toLocaleTimeString(document.documentElement.lang, { hour: "2-digit", minute: "2-digit" })
  }

  // The answer of the server replaces the form (empty, or with its error): the new field takes the focus back
  fieldTargetConnected(field) {
    if (this.focusAfterSend) field.focus()
    this.focusAfterSend = false
  }

  sent() {
    this.focusAfterSend = true
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
