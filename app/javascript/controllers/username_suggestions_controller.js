import { Controller } from "@hotwired/stimulus"

// Suggests usernames from the database while the game master types the one of a player to invite.
// The suggestions fill a <datalist> tied to the field: the browser shows them, with the keyboard and to screen
// readers, and the field stays a plain text field (without JavaScript, the username is typed in full).
// A short pause after the last key before asking the server, so that it is not asked at every key
const typingPause = 200

export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String, minimumLength: { type: Number, default: 2 } }

  disconnect() {
    clearTimeout(this.typingTimer)
  }

  suggest() {
    clearTimeout(this.typingTimer)
    this.typingTimer = setTimeout(() => this.fetchSuggestions(), typingPause)
  }

  async fetchSuggestions() {
    const typedText = this.inputTarget.value.trim()
    if (typedText.length < this.minimumLengthValue) return this.showSuggestions([])

    const suggestionsUrl = new URL(this.urlValue, window.location.origin)
    suggestionsUrl.searchParams.set("query", typedText)
    const response = await fetch(suggestionsUrl, { headers: { Accept: "application/json" } })
    if (response.ok) this.showSuggestions(await response.json())
  }

  showSuggestions(usernames) {
    const options = usernames.map((username) => {
      const option = document.createElement("option")
      option.value = username
      return option
    })
    this.listTarget.replaceChildren(...options)
  }
}
