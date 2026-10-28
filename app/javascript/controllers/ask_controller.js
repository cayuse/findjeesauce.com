import { Controller } from "@hotwired/stimulus"

// "Ask your store": copy the request, and count it for the demand map (chain
// and coarse place only). A chain tap counts once per chain; a copy with no
// chain tap (they'll ask in person) counts as "other" when they leave.
export default class extends Controller {
  static targets = ["text", "copy", "thanks"]
  static values = { url: String, place: Object }

  connect() {
    this.chains = new Set()
    this.leave = () => { if (this.copied && this.chains.size === 0) this.send("other") }
    addEventListener("pagehide", this.leave)
  }

  disconnect() {
    removeEventListener("pagehide", this.leave)
  }

  select() {
    this.textTarget.select()
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textTarget.value)
    } catch (error) {
      this.select()
      document.execCommand?.("copy")
    }
    this.copied = true
    this.copyTarget.textContent = "Copied!"
    this.thanksTarget.classList.remove("hidden")
  }

  record({ params: { chain } }) {
    if (this.chains.has(chain)) return
    this.chains.add(chain)
    this.send(chain)
  }

  send(chain) {
    const body = new FormData()
    body.append("chain", chain)
    Object.entries(this.placeValue).forEach(([key, value]) => body.append(key, value))
    navigator.sendBeacon?.(this.urlValue, body) || fetch(this.urlValue, { method: "POST", body, keepalive: true }).catch(() => {})
  }
}
