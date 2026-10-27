import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps, mapsKey } from "lib/google_maps"

// The search form. With a maps key, a typed place is geocoded in the browser
// and sent as lat/lng (nearest-first results). Without one, the text goes to
// the server as-is and is matched against store ZIPs and cities.
// "Use my location" asks the browser for coordinates; no key needed.
export default class extends Controller {
  static targets = ["query", "lat", "lng", "locate", "message"]

  async submit(event) {
    this.latTarget.value = ""
    this.lngTarget.value = ""
    const query = this.queryTarget.value.trim()
    if (!query || !mapsKey()) return

    event.preventDefault()
    try {
      const maps = await loadGoogleMaps()
      const { Geocoder } = await maps.importLibrary("geocoding")
      const { results } = await new Geocoder().geocode({ address: query, componentRestrictions: { country: "US" } })
      if (results?.length) {
        const loc = results[0].geometry.location
        this.latTarget.value = loc.lat().toFixed(5)
        this.lngTarget.value = loc.lng().toFixed(5)
      }
    } catch (error) {
      // Geocoding failed (no match, quota, network): fall back to text search.
    }
    this.element.submit()
  }

  locate() {
    if (!("geolocation" in navigator)) return this.say("Your browser can't share its location. Try a ZIP code.")

    this.locateTarget.disabled = true
    this.locateTarget.textContent = "Finding you…"
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.queryTarget.value = ""
        this.latTarget.value = position.coords.latitude.toFixed(5)
        this.lngTarget.value = position.coords.longitude.toFixed(5)
        this.element.submit()
      },
      () => {
        this.locateTarget.disabled = false
        this.locateTarget.textContent = "Use my location"
        this.say("We couldn't get your location. Try a ZIP code instead.")
      },
      { timeout: 10000, maximumAge: 300000 }
    )
  }

  say(text) {
    this.messageTarget.textContent = text
    this.messageTarget.classList.remove("hidden")
  }
}
