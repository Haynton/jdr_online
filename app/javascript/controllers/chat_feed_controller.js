import { Controller } from "@hotwired/stimulus"

// The feed of the chat of the game room (game_rooms/_chat), on the island with chat_island_controller.js. A line comes
// from the page or live from the channel, the same for everyone: here each reader sees their own lines marked
// (data-own), a message that follows one of the same author by less than five minutes without its header again
// (data-continued), and the time in their own time zone.
// Unread lines (the others' messages and the events, never one's own): while the chat is folded, a gold round in its
// header says how many; unfolded, a « Nouveaux messages » line comes before the first one and the feed goes to it.
// While the reader is further up, the feed stays where it is and a pill takes them down. The last line seen is kept
// in this browser for each table (localStorage): back in the room, what came meanwhile is still unread.
// The field grows with its text; Enter sends, Shift + Enter goes to the line; a message sent, the field is emptied
// and keeps the focus
const BOTTOM_MARGIN = 48
const CONTINUED_WITHIN_MS = 5 * 60 * 1000
const MAX_SHOWN_COUNT = 9

export default class extends Controller {
  static targets = [
    "scroller", "line", "time", "form", "field", "badge", "unreadText", "newMessagesButton", "dividerTemplate"
  ]

  static values = { currentUserId: String, tableId: String, unreadOne: String, unreadOther: String }

  connect() {
    this.newestLineId = this.lastLineId()
    this.seenLineId = this.readSeenLineId()
    if (this.seenLineId === null) this.markAllSeen()
    // Only once chat_island_controller.js, on the same element, has folded the chat as it was left: loaded on its
    // own, it may connect after this one, and then tells it by chat-island:folded
    if (this.element.hasAttribute("data-chat-island-ready")) this.showUnread()
  }

  lineTargetConnected(line) {
    const own = this.isOwn(line)
    line.toggleAttribute("data-own", own)
    line.toggleAttribute("data-continued", this.continuesPrevious(line))
    if (this.newestLineId === undefined || this.lineId(line) <= this.newestLineId) return

    this.newestLineId = this.lineId(line)
    this.lineArrived(own)
  }

  timeTargetConnected(time) {
    const shownTime = new Date(time.getAttribute("datetime"))
    time.textContent = shownTime.toLocaleTimeString(document.documentElement.lang, { hour: "2-digit", minute: "2-digit" })
  }

  // Told by chat_island_controller.js: folded, the count; unfolded, the unread lines are shown and read
  foldChanged() {
    this.showUnread()
  }

  // A folded chat has no scroll: its lines are read once it is unfolded
  scrolled() {
    if (!this.folded && this.nearBottom) this.markAllSeen()
  }

  readNewMessages() {
    this.scrollToBottom()
    this.markAllSeen()
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

  lineArrived(own) {
    if (own) {
      this.readNewMessages()
    } else if (this.folded) {
      this.showCount()
    } else if (this.nearBottom) {
      this.readNewMessages()
    } else {
      this.newMessagesButtonTarget.hidden = false
    }
  }

  // Folded: the count in the header. Unfolded: the line before the first unread one, the feed taken to it
  showUnread() {
    if (this.folded) return this.showCount()

    const firstUnread = this.unreadLines()[0]
    this.placeDivider(firstUnread)
    if (firstUnread) {
      this.scrollerTarget.scrollTop = this.divider.offsetTop - this.scrollerTarget.clientHeight / 3
    } else {
      this.scrollToBottom()
    }
    this.markAllSeen()
  }

  showCount() {
    const count = this.unreadLines().length
    this.badgeTarget.hidden = count === 0
    this.badgeTarget.textContent = count > MAX_SHOWN_COUNT ? `${MAX_SHOWN_COUNT}+` : String(count)
    const text = count === 1 ? this.unreadOneValue : this.unreadOtherValue
    this.unreadTextTarget.textContent = count === 0 ? "" : text.replace("%{count}", count)
  }

  placeDivider(firstUnread) {
    this.divider?.remove()
    this.divider = null
    if (!firstUnread) return

    this.divider = this.dividerTemplateTarget.content.firstElementChild.cloneNode(true)
    firstUnread.before(this.divider)
  }

  markAllSeen() {
    this.seenLineId = this.newestLineId
    this.newMessagesButtonTarget.hidden = true
    this.showCount()
    this.writeSeenLineId()
  }

  unreadLines() {
    return this.lineTargets.filter((line) => this.lineId(line) > this.seenLineId && !this.isOwn(line))
  }

  isOwn(line) {
    return Boolean(line.dataset.authorId) && line.dataset.authorId === this.currentUserIdValue
  }

  continuesPrevious(line) {
    const previous = line.previousElementSibling
    if (!previous || previous.dataset.kind !== "message" || line.dataset.kind !== "message") return false
    if (!line.dataset.authorId || previous.dataset.authorId !== line.dataset.authorId) return false

    return new Date(line.dataset.createdAt) - new Date(previous.dataset.createdAt) < CONTINUED_WITHIN_MS
  }

  lineId(line) {
    return Number(line.dataset.lineId)
  }

  lastLineId() {
    const lastLine = this.lineTargets.at(-1)
    return lastLine ? this.lineId(lastLine) : 0
  }

  // The body of the chat is hidden while it is folded (chat_island_controller.js)
  get folded() {
    return this.scrollerTarget.closest("#game-room-chat-body").hidden
  }

  get nearBottom() {
    const { scrollHeight, scrollTop, clientHeight } = this.scrollerTarget
    return scrollHeight - scrollTop - clientHeight < BOTTOM_MARGIN
  }

  scrollToBottom() {
    this.scrollerTarget.scrollTop = this.scrollerTarget.scrollHeight
  }

  get storageKey() {
    return `game_room_chat_seen_${this.tableIdValue}`
  }

  // Storage can be blocked (private window): the chat still works, only what was read is forgotten on reload
  readSeenLineId() {
    try {
      const seenLineId = localStorage.getItem(this.storageKey)
      return seenLineId === null ? null : Number(seenLineId)
    } catch {
      return null
    }
  }

  writeSeenLineId() {
    try {
      localStorage.setItem(this.storageKey, String(this.seenLineId))
    } catch {
      // Nothing to do: back in the room, the lines of now count as unread again
    }
  }
}
