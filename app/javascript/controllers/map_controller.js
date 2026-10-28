import { Controller } from "@hotwired/stimulus"
import { MarkerClusterer } from "@googlemaps/markerclusterer"
import { loadGoogleMaps } from "lib/google_maps"

// A live Google map of stores, zoomable to street level.
// - stores: the pins to show (search results, one store page)
// - feed:   a URL to fetch every store from instead (the default map before a
//           search); pins merge into numbered clusters until zoomed in
// - center: the searcher's point, included in the fitted view
// - linkBase: where a store's page lives ("/stores/" or "/embed/stores/")
// - lids:     flavor name => lid image URL, for the popup's flavor pills
// - flavor:   a chosen flavor's name. The all-stores map then shows only the
//             stores that carry it; a search map dims the ones that don't
//             (a store with no flavor list stays as it is: unknown, not "no")
export default class extends Controller {
  static values = { stores: Array, feed: String, center: Object, linkBase: String, zoom: { type: Number, default: 12 },
                    flavor: String, flavorSlug: String, lids: Object }

  // The lower 48, for the all-stores view (fitting every store would zoom out
  // to include Alaska and Hawaii).
  US = { center: { lat: 39.5, lng: -98.35 }, zoom: 4 }

  async connect() {
    let maps
    try { maps = await loadGoogleMaps() } catch { maps = null }
    if (!maps) return this.element.remove()

    let stores = this.hasFeedValue ? await this.fetchFeed() : this.storesValue
    if (this.hasFeedValue && this.flavorValue) stores = stores.filter((s) => this.state(s) === "carries")
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
      const dim = this.state(store) === "doesnt"
      const marker = new Marker({ position: { lat: store.lat, lng: store.lng }, title: store.name,
                                  opacity: dim ? 0.35 : 1, zIndex: dim ? 1 : 10 })
      if (store.url) marker.addListener("click", () => this.open(map, marker, store))
      return marker
    })

    if (all) {
      new MarkerClusterer({ map, markers, renderer: { render: (cluster) => this.clusterMarker(maps, cluster) } })
      // Start on wherever the stores are in the lower 48 (Alaska and Hawaii
      // would zoom the whole view out); their pins are a pan or zoom away.
      const lower48 = stores.filter((s) => s.lat > 24 && s.lat < 50 && s.lng > -125 && s.lng < -66)
      if (lower48.length) {
        const bounds = new maps.LatLngBounds()
        lower48.forEach((s) => bounds.extend(s))
        map.fitBounds(bounds, 24)
      }
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

  // A cluster: a JeeSauce-teal circle with the store count. Drawn as a
  // classic marker, because the library's default needs a Google "Map ID".
  clusterMarker(maps, { count, position }) {
    const size = count < 10 ? 34 : count < 100 ? 42 : 52
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 40 40">
      <circle cx="20" cy="20" r="19" fill="#1badcf" fill-opacity="0.25"/>
      <circle cx="20" cy="20" r="14" fill="#1badcf" stroke="#fff" stroke-width="2"/></svg>`
    return new maps.Marker({
      position,
      icon: { url: `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`, scaledSize: new maps.Size(size, size), anchor: new maps.Point(size / 2, size / 2) },
      label: { text: String(count), color: "#ffffff", fontSize: "12px", fontWeight: "700" },
      title: `${count} stores`,
      zIndex: 1000 + count,
    })
  }

  async fetchFeed() {
    try {
      const response = await fetch(this.feedValue, { headers: { Accept: "application/json" } })
      const { data } = await response.json()
      const base = this.linkBaseValue || "/stores/"
      return data.map((s) => ({
        lat: s.lat, lng: s.lng, name: s.name,
        address: [s.street, [s.city, s.state].filter(Boolean).join(", ")].filter(Boolean).join(" · "),
        flavors: s.flavors || [],
        url: base + s.slug + (this.flavorSlugValue ? `?flavor=${encodeURIComponent(this.flavorSlugValue)}` : ""),
      }))
    } catch {
      return []
    }
  }

  // "carries", "doesnt" or "unknown" for the chosen flavor (null when none).
  state(store) {
    if (!this.flavorValue) return null
    if (!store.flavors?.length) return "unknown"
    return store.flavors.includes(this.flavorValue) ? "carries" : "doesnt"
  }

  // The pin's popup: flavor pills (mini lid + name) on top, then the store
  // name as a big underlined link with an arrow, the address, and a "store
  // page" line that reads as a link. Built as elements: store names are
  // data, never HTML.
  open(map, marker, store) {
    const el = (tag, css, text) => {
      const node = document.createElement(tag)
      if (css) node.style.cssText = css
      if (text) node.textContent = text
      return node
    }
    const box = el("div", "font: 14px/1.35 Questrial, system-ui, sans-serif; max-width: 260px; padding: 2px 2px 4px")

    const flavors = el("div", "display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 8px")
    if (store.flavors?.length) {
      store.flavors.forEach((name) => {
        const chosen = name === this.flavorValue
        const pill = el("span", "display: inline-flex; align-items: center; gap: 5px; border: 1px solid " +
          (chosen ? "#000; background: #000; color: #fff; font-weight: 700" : "#e8e2d4; background: #fff") +
          "; border-radius: 999px; padding: 2px 9px 2px 2px; font-size: 12px")
        const lid = this.lidsValue[name]
        if (lid) {
          const img = el("img", "width: 20px; height: 20px; border-radius: 999px")
          img.src = lid
          img.alt = ""
          pill.append(img)
        } else {
          pill.style.paddingLeft = "9px"
        }
        pill.append(name)
        flavors.append(pill)
      })
    } else {
      flavors.append(el("span", "color: #55524c; font-size: 12px", "Flavors unknown: call ahead"))
    }
    box.append(flavors)

    const name = el("a", "display: block; font: 700 18px/1.2 Archivo, system-ui, sans-serif; color: #000; " +
      "text-decoration: underline; text-underline-offset: 3px; text-decoration-thickness: 2px")
    name.href = store.url
    name.textContent = `${store.name} →`
    box.append(name)
    if (store.address) box.append(el("div", "margin-top: 3px; color: #55524c; font-size: 13px", store.address))

    const go = el("a", "display: block; margin-top: 10px; font-weight: 700; font-size: 14px; color: #13839e; " +
      "text-decoration: underline; text-underline-offset: 3px")
    go.href = store.url
    go.textContent = "Open store page: share · directions →"
    box.append(go)

    this.info.setContent(box)
    this.info.open({ map, anchor: marker })
  }
}
