import { Controller } from "@hotwired/stimulus"

// The spells to choose at the Spells step (game_tables/character_steps/_spell_choices): the count of each group
// ("2 sur 3 choisis", in red past the number allowed: data-invalid) follows the boxes ticked. The search hides the
// spells whose name does not hold what is typed, whatever the accents and the capitals, and the pills filter them by
// level, school, concentration or ritual, and the spells chosen: within a group the values add up, between the groups
// they combine (as table_filter_controller.js). An aid: the server checks the spells chosen
// (CharacterSpellsValidator). The search and the pills are rendered hidden and shown here: nothing without JavaScript
export default class extends Controller {
  static targets = ["tools", "search", "pill", "spell", "block", "group", "status", "noMatch"]

  connect() {
    if (this.hasToolsTarget) this.toolsTarget.hidden = false
    this.count = this.count.bind(this)
    this.element.addEventListener("change", this.count)
    this.count()
  }

  disconnect() {
    this.element.removeEventListener("change", this.count)
  }

  // Each count of a group: by default every box ticked; the spellbook of a wizard counts its own boxes and the spells
  // prepared theirs (data-count-for). « Préparé » is enabled once the spell is in the book, unticked when it goes
  count(event) {
    const bookBox = event?.target?.closest?.("[data-book-box]")
    const preparedBox = bookBox?.closest("li").querySelector("[data-prepared-box]")
    if (preparedBox) {
      preparedBox.disabled = !bookBox.checked
      if (!bookBox.checked) preparedBox.checked = false
    }
    this.statusTargets.forEach((status) => {
      const group = this.groupTargets.find((target) => target.contains(status))
      const boxes = status.dataset.countFor ? `input[data-count-for="${status.dataset.countFor}"]` : "input[type=checkbox]"
      const chosenCount = group.querySelectorAll(`${boxes}:checked:not(:disabled)`).length
      const allowedCount = Number(status.dataset.allowed ?? group.dataset.allowed)
      const template = status.dataset.template ?? group.dataset.template
      status.textContent = template.replace("%{chosen}", chosenCount).replace("%{allowed}", allowedCount)
      status.toggleAttribute("data-invalid", chosenCount > allowedCount)
    })
  }

  toggle({ currentTarget: pill }) {
    pill.setAttribute("aria-pressed", String(pill.getAttribute("aria-pressed") !== "true"))
    this.filter()
  }

  filter() {
    const query = searchable(this.searchTarget.value)
    const pressedValues = this.pressedValuesByGroup()
    this.spellTargets.forEach((spell) => {
      spell.hidden = !spell.dataset.name.includes(query) || !this.isMatching(spell, pressedValues)
    })
    this.blockTargets.forEach((block) => { block.hidden = !block.querySelector("li:not([hidden])") })
    this.noMatchTarget.hidden = this.spellTargets.some((spell) => !spell.hidden)
  }

  // { level: ["1"], school: [], casting: ["ritual"], chosen: [] }: the values of the pressed pills, by group
  pressedValuesByGroup() {
    return this.pillTargets.reduce((pressedValues, pill) => {
      const { group, value } = pill.dataset
      pressedValues[group] ||= []
      if (pill.getAttribute("aria-pressed") === "true") pressedValues[group].push(value)
      return pressedValues
    }, {})
  }

  isMatching(spell, pressedValues) {
    return Object.entries(pressedValues).every(([group, values]) => {
      return values.length === 0 || values.some((value) => this.spellValues(spell, group).includes(value))
    })
  }

  // A spell may be both concentration and ritual (casting: "concentration ritual"); chosen: its box ticked
  spellValues(spell, group) {
    if (group === "chosen") return spell.querySelector("input[type=checkbox]").checked ? ["chosen"] : []

    return (spell.dataset[group] || "").split(" ")
  }
}

// "Détection" and "detection" find each other, as CharacterSheets::SpellChoicesHelper#spell_search_name on the server
function searchable(text) {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim()
}
