import { Controller } from "@hotwired/stimulus"

// Saves its form in the background while it is filled (decision: on a step of the creation of a character, nothing
// typed is lost, even when the tab closes or the player leaves by the navigation): a choice at once, a typed text after
// a short pause, and whatever is not saved yet when the page is left. The server keeps what is valid and answers
// nothing (GameTables::CharacterStepsController#draft); nothing is shown (decision). Sending the form itself (Continue,
// Back, a step of the band) saves it already: what was waiting is dropped. Without JavaScript, the buttons still save
const typingPauseInMilliseconds = 800

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.hasUnsavedChanges = false
    this.saveBeforeLeaving = this.saveBeforeLeaving.bind(this)
    this.saveWhenHidden = this.saveWhenHidden.bind(this)
    document.addEventListener("turbo:visit", this.saveBeforeLeaving)
    document.addEventListener("visibilitychange", this.saveWhenHidden)
    window.addEventListener("pagehide", this.saveBeforeLeaving)
  }

  disconnect() {
    clearTimeout(this.typingTimer)
    document.removeEventListener("turbo:visit", this.saveBeforeLeaving)
    document.removeEventListener("visibilitychange", this.saveWhenHidden)
    window.removeEventListener("pagehide", this.saveBeforeLeaving)
  }

  // While typing: saved once the player pauses
  saveSoon(event) {
    if (!isSentWithTheForm(event.target)) return

    this.hasUnsavedChanges = true
    clearTimeout(this.typingTimer)
    this.typingTimer = setTimeout(() => this.send(), typingPauseInMilliseconds)
  }

  // A choice made, a text left: saved at once
  save(event) {
    if (!isSentWithTheForm(event.target)) return

    this.hasUnsavedChanges = true
    this.send()
  }

  cancel() {
    clearTimeout(this.typingTimer)
    this.hasUnsavedChanges = false
  }

  // Leaving does not wait for a save on its way: the last values go at once
  saveBeforeLeaving() {
    if (this.hasUnsavedChanges) this.send({ leaving: true })
  }

  saveWhenHidden() {
    if (document.visibilityState === "hidden") this.saveBeforeLeaving()
  }

  // One save at a time, so that an older one never arrives last: a change made meanwhile is sent once it is back. A
  // save that failed (no network) is tried again with the next change or when leaving, not in a loop
  async send({ leaving = false } = {}) {
    clearTimeout(this.typingTimer)
    if (this.isSaving && !leaving) return

    this.isSaving = true
    this.hasUnsavedChanges = false
    const isSaved = await this.request().then((response) => response.ok, () => false)
    this.isSaving = false
    if (!isSaved) this.hasUnsavedChanges = true
    else if (this.hasUnsavedChanges && !leaving) this.send()
  }

  // keepalive: the request still goes when the page is being left. The form carries its method (_method=patch) and
  // its token; new FormData lets the other controllers adjust what is sent (formdata: the scores as typed)
  request() {
    return fetch(this.urlValue, {
      method: "POST",
      body: new FormData(this.element),
      keepalive: true,
      headers: { "X-CSRF-Token": csrfToken(), Accept: "text/html" }
    })
  }
}

// A field without a name (the search of the spells, "Assign a result") is not sent: nothing to save
function isSentWithTheForm(field) {
  return Boolean(field.name)
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content ?? ""
}
