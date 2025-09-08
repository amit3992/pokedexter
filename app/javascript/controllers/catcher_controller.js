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
    
    if (data.limit_reached) {
      el.innerHTML = `<div class="text-red-500 font-medium">${data.error}</div>
                     <div class="mt-2"><a href="/caught" class="text-blue-500 underline">Go to your collection</a> to release some Pokémon.</div>`
    } else if (data.success) {
      el.innerHTML = `<div class="text-green-500 font-medium">${data.message}</div>
                     <div class="text-sm mt-1">You now have ${data.pokemon_count}/10 Pokémon.</div>`
    } else {
      el.innerHTML = `<div class="text-amber-500 font-medium">${data.message || data.error || "Something went wrong."}</div>`
    }
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta && meta.content
  }
}