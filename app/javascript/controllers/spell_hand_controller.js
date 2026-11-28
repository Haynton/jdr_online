import { Controller } from "@hotwired/stimulus"

// The kinds of boxes whose cards go in the hand (not the spellbook: its spells prepared do)
const IN_HAND = ["pick", "prepared", "cantrips", "spell"]
// A card of the rows (w-41, 200 px high), made small in a pile and in its fan
const CARD_WIDTH = 164
const CARD_HEIGHT = 200
const PACKET_CARD_SCALE = 0.55

// The spells at the Spells step (game_tables/character_steps/_spell_cards, _spell_quest). Each part counts its cards
// picked, one count per kind of spell it asks (data-count-for: pick, prepared, cantrips, spell: « 2 à choisir »,
// « Main pleine », in red past the number allowed) and, once a count is reached, disables the other boxes of that kind
// (their card fades, data-faded) until one is taken back; a spell picked in a part fades in the others (a spell known
// twice is refused). A wizard writes cards in his spellbook (book) and prepares those written (prepared). The tabs show
// one part at a time (select), its pills bring its row to a level (jump). Every card picked goes in the hand at the foot
// (_spell_hand_cards), one packet per part under the row, unfolded with a click; a click on a card puts it back. The search and the intents filter the cards. An aid:
// the server checks the spells chosen. The tools and the hand are shown by CSS when JavaScript runs (scripted:)
export default class extends Controller {
  static targets = ["status", "bookStatus", "card", "tools", "search", "intent", "empty", "mark", "partButton", "partCards", "hand"]

  connect() {
    this.refresh()
    if (this.hasPartButtonTarget) this.showPart(this.partButtonTargets[0].dataset.row)
  }

  refresh() {
    this.bookStatusTargets.forEach((status) => this.refreshBook(status))
    this.statusTargets.forEach((status) => this.refreshCount(status))
    this.fadeTakenElsewhere()
    this.element.querySelectorAll("[data-part-count]").forEach((count) => { count.textContent = this.countOf(count.dataset.partCount) })
    this.fillPackets()
  }

  refreshCount(status) {
    const { countFor, row } = status.dataset
    const allowed = Number(status.dataset.allowed)
    const picks = this.boxes(row, countFor)
    const chosen = picks.filter((box) => box.checked).length
    this.limit(picks, chosen >= allowed, { fade: countFor !== "prepared" })
    this.writeStatus(status, chosen, allowed)
  }

  // The spellbook: its cards fade once it is full; « Préparé » only on a spell written in it
  refreshBook(status) {
    const books = this.boxes(status.dataset.row, "book")
    const written = books.filter((box) => box.checked).length
    const allowed = Number(status.dataset.allowed)
    this.limit(books, written >= allowed, { fade: true })
    status.textContent = status.dataset.template.replace("__CHOSEN__", written).replace("__ALLOWED__", allowed)
    status.toggleAttribute("data-invalid", written > allowed)
    this.boxes(status.dataset.row, "prepared").forEach((prepared) => {
      const inBook = prepared.closest("li").querySelector("[data-card-box]").checked
      if (!inBook) prepared.checked = false
      prepared.disabled = !inBook
    })
  }

  // A full count disables its boxes not ticked; « Préparé » keeps what refreshBook decided (not in the book)
  limit(boxes, full, { fade }) {
    boxes.forEach((box) => {
      const blocked = full && !box.checked
      if (blocked) box.disabled = true
      else if (box.dataset.countFor !== "prepared") box.disabled = false
      if (fade) box.closest("li").toggleAttribute("data-faded", blocked)
    })
  }

  // A spell ticked in a part (or given: always prepared) is disabled and faded in the other parts
  fadeTakenElsewhere() {
    const cardBoxes = [...this.element.querySelectorAll("[data-card-box]")]
    cardBoxes.filter((box) => !box.checked && box.dataset.countFor).forEach((box) => {
      const row = box.closest("li").dataset.row
      const taken = cardBoxes.some((other) => other.checked && other.value === box.value && other.closest("li").dataset.row !== row)
      if (!taken) return

      box.disabled = true
      box.closest("li").toggleAttribute("data-faded", true)
    })
  }

  boxes(row, countFor) {
    return [...this.element.querySelectorAll(`li[data-row="${row}"] input[data-count-for="${countFor}"]`)]
  }

  writeStatus(status, chosen, allowed) {
    const { leftOne, leftOther, full, over, prefix = "" } = status.dataset
    const left = allowed - chosen
    let text
    if (chosen > allowed) text = over.replace("__CHOSEN__", chosen).replace("__ALLOWED__", allowed)
    else if (left === 0) text = full
    else text = left === 1 ? leftOne : leftOther.replace("__COUNT__", left)
    status.textContent = prefix + text
    status.toggleAttribute("data-invalid", chosen > allowed)
  }

  // « 1/2 »: the spells picked in a part out of those it asks, every kind counted
  countOf(row) {
    const statuses = this.statusTargets.filter((status) => status.dataset.row === row)
    const allowed = statuses.reduce((total, status) => total + Number(status.dataset.allowed), 0)
    const chosen = statuses.reduce((total, status) => total + this.boxes(row, status.dataset.countFor).filter((box) => box.checked).length, 0)
    return `${chosen}/${allowed}`
  }

  // Each packet of the hand (one per part): its count, and its cards picked, overlapping while folded, side by side
  // once unfolded (the other packets then keep only their name and count)
  fillPackets() {
    if (!this.hasHandTarget) return

    this.handTarget.querySelectorAll("[data-packet]").forEach((packet) => {
      const row = packet.dataset.packet
      const picked = [...this.element.querySelectorAll(`li[data-row="${row}"] input[data-count-for]:checked`)]
        .filter((box) => IN_HAND.includes(box.dataset.countFor))
      const open = this.openPacket === row && picked.length > 0
      packet.toggleAttribute("data-open", open)
      packet.querySelector("[data-packet-count]").textContent = this.countOf(row)
      packet.querySelector("button[aria-expanded]").setAttribute("aria-expanded", String(open))
      const cards = packet.querySelector("[data-packet-cards]")
      cards.hidden = Boolean(this.openPacket) && !open
      this.layPacket(cards, picked, open, row)
    })
  }

  // Folded, each card 14 px right of the one under it (closer past ten); unfolded, as far apart as the room allows
  layPacket(cards, picked, open, row) {
    const width = CARD_WIDTH * PACKET_CARD_SCALE
    const room = cards.parentElement.clientWidth || this.handTarget.clientWidth
    const count = picked.length
    const step = count < 2 ? 0 : open ? Math.min(width + 6, (room - width) / (count - 1)) : Math.min(14, 140 / (count - 1))
    cards.style.width = `${width + step * Math.max(count - 1, 0)}px`
    if (count === 0) {
      const place = document.createElement("span")
      place.className = "absolute bottom-0 left-0 rounded-[10px] border border-dashed border-field-line"
      place.style.width = `${width}px`
      place.style.height = `${CARD_HEIGHT * PACKET_CARD_SCALE}px`
      cards.replaceChildren(place)
      return
    }
    cards.replaceChildren(...picked.map((box, position) => {
      const card = document.createElement("button")
      card.type = "button"
      card.className = this.handTarget.dataset.packetCardClasses
      card.style.left = `${position * step}px`
      const name = box.closest("li").dataset.name
      card.title = open ? this.element.dataset.spellHandRemoveTemplate.replace("__NAME__", name) : name
      card.setAttribute("aria-label", card.title)
      if (!open) card.tabIndex = -1
      card.append(this.miniCard(box, PACKET_CARD_SCALE))
      card.addEventListener("click", () => (open ? box.click() : this.togglePacketNamed(row)))
      return card
    }))
  }

  // A packet unfolds on its own line, the one open folds
  togglePacket({ currentTarget: button }) {
    this.togglePacketNamed(button.dataset.row)
  }

  // Unfolded, its part is chosen above too: its tab and its row of cards
  togglePacketNamed(row) {
    this.openPacket = this.openPacket === row ? null : row
    if (this.openPacket) this.showPart(row)
    this.fillPackets()
  }

  // The real face of a card, made small: a copy of its label, its box kept ticked but nameless, never sent
  miniCard(box, scale) {
    const place = box.closest("li")
    const frame = document.createElement("span")
    frame.className = "relative block overflow-hidden rounded-[14px]"
    frame.style.width = `${CARD_WIDTH * scale}px`
    frame.style.height = `${CARD_HEIGHT * scale}px`
    frame.style.setProperty("--tone", getComputedStyle(place).getPropertyValue("--tone"))
    const face = place.querySelector("label").cloneNode(true)
    face.removeAttribute("for")
    face.querySelectorAll("input").forEach((input) => {
      input.removeAttribute("name")
      input.removeAttribute("id")
      // A copy is no box of a card: the counts and fadeTakenElsewhere read only the real ones (a copy, out of any
      // row, stopped the refresh, and a card put back stayed in its packet)
      delete input.dataset.cardBox
      delete input.dataset.countFor
      input.checked = true
      input.tabIndex = -1
    })
    face.setAttribute("aria-hidden", "true")
    face.style.cssText = `position:absolute;top:0;left:0;width:${CARD_WIDTH}px;transform:scale(${scale});transform-origin:top left;pointer-events:none`
    frame.append(face)
    return frame
  }

  // The tabs of the parts (_spell_quest): the one chosen is pressed, its sentence, its counts and its cards only show
  select({ currentTarget: button }) {
    this.showPart(button.dataset.row)
  }

  showPart(row) {
    this.partButtonTargets.forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.row === row)))
    this.partCardsTargets.forEach((cards) => {
      cards.hidden = cards.dataset.row !== row
      cards.classList.remove("scripted:hidden")
    })
    this.partCardsTargets.find((cards) => !cards.hidden)?.querySelector("ul[data-card-row-target=row]")?.dispatchEvent(new Event("scroll"))
  }

  // A pill brings the row of its part to the first card of its level
  jump({ currentTarget: mark }) {
    const card = [...this.element.querySelectorAll(`li[data-row="${mark.dataset.row}"][data-level="${mark.dataset.level}"]`)]
      .find((item) => !item.hidden)
    if (!card) return

    const isMotionReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    card.closest("ul").scrollTo({ left: card.offsetLeft, behavior: isMotionReduced ? "auto" : "smooth" })
  }

  // The pill of the level of the first card in sight of a row is pressed
  followRow({ currentTarget: row }) {
    const marks = [...row.closest("section").querySelectorAll("[data-spell-hand-target~=mark]")]
    if (marks.length === 0) return

    const cards = [...row.querySelectorAll("li[data-level]")].filter((item) => !item.hidden)
    // At the end of the row, its last cards cannot come to its start: the level of the last one is the one in sight
    const atEnd = row.scrollLeft + row.clientWidth >= row.scrollWidth - 1
    const inSight = atEnd ? cards.at(-1) : cards.find((item) => item.offsetLeft + item.offsetWidth > row.scrollLeft + 1)
    if (inSight) marks.forEach((mark) => mark.setAttribute("aria-pressed", String(mark.dataset.level === inSight.dataset.level)))
  }

  // One intent at a time, « Tout » (no value) shows every card
  choose({ currentTarget: pill }) {
    this.intentTargets.forEach((intent) => intent.setAttribute("aria-pressed", String(intent === pill)))
    this.filter()
  }

  // Enter in the search does not send the step (the first button of the form is Continue)
  keepSearching(event) {
    event.preventDefault()
  }

  // The cards whose name holds what is typed (whatever the accents and the capitals) and that serve the intent pressed;
  // each row back to its start
  filter() {
    const intent = this.intentTargets.find((pill) => pill.getAttribute("aria-pressed") === "true")?.dataset.value
    const query = this.hasSearchTarget ? searchable(this.searchTarget.value) : ""
    this.cardTargets.forEach((card) => {
      const servesIntent = !intent || card.dataset.intents.split("|").includes(intent)
      card.hidden = !servesIntent || !card.dataset.search.includes(query)
    })
    this.emptyTargets.forEach((empty) => {
      empty.hidden = this.cardTargets.some((card) => card.dataset.row === empty.dataset.row && !card.hidden)
    })
    this.element.querySelectorAll("[data-card-row-target=row]").forEach((row) => {
      row.scrollLeft = 0
      row.dispatchEvent(new Event("scroll"))
    })
  }
}

// "Détection" and "detection" find each other, as CharacterSheets::SpellChoicesHelper#spell_search_name on the server
function searchable(text) {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim()
}
