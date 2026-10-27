import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "lib/google_maps"

// A map of stores: one pin each, fitted to show them all (plus the searcher's
// point when given). Tapping a pin opens the store's name and page link.
export default class extends Controller {
  static values = { stores: Array, center: Object, zoom: { type: Number, default: 12 } }

  async connect() {
    let maps
    try { maps = await loadGoogleMaps() } catch { maps = null }
    if (!maps || !this.storesValue.length) return this.element.remove()

    const { Map, InfoWindow } = await maps.importLibrary("maps")
    const { Marker } = await maps.importLibrary("marker")
    const map = new Map(this.element, {
      center: this.storesValue[0],
      zoom: this.zoomValue,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false,
      clickableIcons: false,
    })
    const info = new InfoWindow()
    const bounds = new maps.LatLngBounds()

    this.storesValue.forEach((store) => {
      const position = { lat: store.lat, lng: store.lng }
      const marker = new Marker({ map, position, title: store.name })
      bounds.extend(position)
      if (store.url) {
        marker.addListener("click", () => {
          const link = document.createElement("a")
          link.href = store.url
          link.textContent = store.name
          link.style.fontWeight = "600"
          info.setContent(link)
          info.open({ map, anchor: marker })
        })
      }
    })

    if (this.hasCenterValue && this.centerValue.lat) bounds.extend(this.centerValue)
    if (this.storesValue.length > 1 || this.hasCenterValue) {
      map.fitBounds(bounds, 48)
    }
  }
}
