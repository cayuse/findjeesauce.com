import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "lib/google_maps"

// The team's demand map: a circle per ~7-mile square where people searched,
// sized by searches; red where they found no store nearby.
export default class extends Controller {
  static values = { places: Array }

  async connect() {
    let maps
    try { maps = await loadGoogleMaps() } catch { return }
    if (!maps) return
    const { Map, Circle, InfoWindow } = await maps.importLibrary("maps")
    const { LatLngBounds } = await maps.importLibrary("core")
    const map = new Map(this.element, { center: { lat: 39.5, lng: -98.35 }, zoom: 4, streetViewControl: false, mapTypeControl: false })
    const info = new InfoWindow()
    const bounds = new LatLngBounds()

    this.placesValue.forEach((place) => {
      const center = { lat: place.lat, lng: place.lng }
      const empty = place.empty > 0
      const circle = new Circle({
        map, center, radius: 4000 + 2500 * Math.sqrt(place.total),
        fillColor: empty ? "#c81e1e" : "#1badcf", fillOpacity: 0.45,
        strokeColor: empty ? "#8a1414" : "#13839e", strokeWeight: 1, clickable: true
      })
      circle.addListener("click", () => {
        info.setContent(`<strong>${[place.zip, place.state].filter(Boolean).join(" ") || "Searches here"}</strong><br>` +
          `${place.total} searches, ${place.empty} with no store nearby` +
          (place.nearest_miles != null ? `<br>Nearest store: ${place.nearest_miles} mi` : ""))
        info.setPosition(center)
        info.open({ map })
      })
      bounds.extend(center)
    })
    if (this.placesValue.length > 1) map.fitBounds(bounds)
  }
}
