import { Controller } from "@hotwired/stimulus"
import { MarkerClusterer } from "@googlemaps/markerclusterer"
import { loadGoogleMaps } from "lib/google_maps"

// A live Google map of stores, zoomable to street level.
// - stores: the pins to show (search results, one store page)
// - feed:   a URL to fetch every store from instead (the default map before a
//           search); pins merge into numbered clusters until zoomed in
// - center: the searcher's point, included in the fitted view
// - linkBase: where a store's page lives ("/stores/" or "/embed/stores/")
export default class extends Controller {
  static values = { stores: Array, feed: String, center: Object, linkBase: String, zoom: { type: Number, default: 12 } }

  // The lower 48, for the all-stores view (fitting every store would zoom out
  // to include Alaska and Hawaii).
  US = { center: { lat: 39.5, lng: -98.35 }, zoom: 4 }

  async connect() {
    let maps
    try { maps = await loadGoogleMaps() } catch { maps = null }
    if (!maps) return this.element.remove()

    const stores = this.hasFeedValue ? await this.fetchFeed() : this.storesValue
    if (!stores.length) return this.element.remove()

    const { Map, InfoWindow } = await maps.importLibrary("maps")
    const { Marker } = await maps.importLibrary("marker")
    const all = this.hasFeedValue
    const map = new Map(this.element, {
      center: all ? this.US.center : stores[0],
      zoom: all ? this.US.zoom : this.zoomValue,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: true,
      clickableIcons: false,
      gestureHandling: "cooperative",
    })
    this.info = new InfoWindow()

    const markers = stores.map((store) => {
      const marker = new Marker({ position: { lat: store.lat, lng: store.lng }, title: store.name })
      if (store.url) marker.addListener("click", () => this.open(map, marker, store))
      return marker
    })

    if (all) {
      new MarkerClusterer({ map, markers })
      return
    }
    markers.forEach((marker) => marker.setMap(map))
    if (stores.length > 1 || (this.hasCenterValue && this.centerValue.lat)) {
      const bounds = new maps.LatLngBounds()
      stores.forEach((s) => bounds.extend(s))
      if (this.hasCenterValue && this.centerValue.lat) bounds.extend(this.centerValue)
      map.fitBounds(bounds, 48)
    }
  }

  async fetchFeed() {
    try {
      const response = await fetch(this.feedValue, { headers: { Accept: "application/json" } })
      const { data } = await response.json()
      const base = this.linkBaseValue || "/stores/"
      return data.map((s) => ({
        lat: s.lat, lng: s.lng, name: s.name,
        address: [s.street, [s.city, s.state].filter(Boolean).join(", ")].filter(Boolean).join(" · "),
        url: base + s.slug,
      }))
    } catch {
      return []
    }
  }

  // Name, address and a link, built as elements (store names are data, never HTML).
  open(map, marker, store) {
    const box = document.createElement("div")
    box.style.cssText = "font: 14px/1.4 Questrial, system-ui, sans-serif; max-width: 240px"
    const name = document.createElement("a")
    name.href = store.url
    name.textContent = store.name
    name.style.cssText = "font-weight: 700; color: #000"
    box.append(name)
    if (store.address) {
      const line = document.createElement("div")
      line.textContent = store.address
      line.style.color = "#55524c"
      box.append(line)
    }
    this.info.setContent(box)
    this.info.open({ map, anchor: marker })
  }
}
