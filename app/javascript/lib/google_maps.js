// Loads the Google Maps JavaScript API once, with the browser key from
// <meta name="google-maps-key">. Resolves to `google.maps`, or null when the
// page has no key (the pages then work as plain lists).
let loading = null

export function mapsKey() {
  return document.querySelector('meta[name="google-maps-key"]')?.content || null
}

export function loadGoogleMaps() {
  const key = mapsKey()
  if (!key) return Promise.resolve(null)
  if (window.google?.maps?.Map) return Promise.resolve(window.google.maps)
  if (loading) return loading

  loading = new Promise((resolve, reject) => {
    const callback = "__findJeeSauceMapsReady"
    window[callback] = () => resolve(window.google.maps)
    const script = document.createElement("script")
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}&loading=async&callback=${callback}&v=weekly`
    script.async = true
    script.onerror = () => { loading = null; reject(new Error("Google Maps failed to load")) }
    document.head.appendChild(script)
  })
  return loading
}
