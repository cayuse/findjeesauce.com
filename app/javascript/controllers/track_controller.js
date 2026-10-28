import { Controller } from "@hotwired/stimulus"

// Counts clicks out to the places that sell JeeSauce (on <body>): the host,
// the store the link sits in ([data-store]), the chosen flavor, and the UTM
// spot for jeesauce.com links. The server keeps only hosts it knows (Click).
const HOSTS = /(^|\.)(heb|albertsons|safeway|jewelosco|betterhealthmarket|instacart|doordash|ubereats|jeesauce|google)\.com$/

export default class extends Controller {
  static values = { url: String, flavor: String }

  connect() {
    this.listener = (event) => this.click(event)
    this.element.addEventListener("click", this.listener, true)
  }

  disconnect() {
    this.element.removeEventListener("click", this.listener, true)
  }

  click(event) {
    const link = event.target.closest?.("a[href^='http']")
    if (!link) return
    const url = new URL(link.href)
    if (!HOSTS.test(url.hostname)) return
    if (url.hostname.endsWith("google.com") && !url.pathname.startsWith("/maps")) return

    const body = new FormData()
    body.append("host", url.hostname)
    const store = link.closest("[data-store]")?.dataset.store
    if (store) body.append("store", store)
    if (this.flavorValue) body.append("flavor", this.flavorValue)
    const spot = url.searchParams.get("utm_content")
    if (spot) body.append("spot", spot)
    navigator.sendBeacon?.(this.urlValue, body)
  }
}
