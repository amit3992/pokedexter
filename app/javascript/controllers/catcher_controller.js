import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { pokemonId: Number }

  async catch() {
    const res = await fetch(`/pokemon/${this.pokemonIdValue}/catch`, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfToken(), "Accept": "application/json" }
    })
    const data = await res.json()
    const el = this.element.querySelector("#result")
    el.textContent = data.message || data.error || "Something went wrong."
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta && meta.content
  }
}