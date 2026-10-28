import { Controller } from "@hotwired/stimulus"

// "Send this store to a friend": the phone's share sheet where there is one,
// copy link, and a count of each share for the "Spread the love" counter.
// Text and Email are plain sms:/mailto: links; this only counts them.
export default class extends Controller {
  static targets = ["native", "link", "copy", "thanks", "captionButton"]
  static values = { url: String, text: String, title: String, recordUrl: String }

  connect() {
    if (navigator.share) this.nativeTarget.hidden = false
  }

  async native() {
    try {
      await navigator.share({ title: this.titleValue, text: this.textValue, url: this.urlValue })
      this.count("native") // the sheet doesn't say which app it went to
    } catch (error) {
      // Closed the sheet without sharing: nothing to count.
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.linkTarget.value)
    } catch (error) {
      // No clipboard (an old browser, or inside a frame): select it to copy by hand.
      this.select()
      document.execCommand?.("copy")
    }
    this.copyTarget.textContent = "Copied!"
    setTimeout(() => { this.copyTarget.textContent = "Copy link" }, 2000)
    this.count("copy")
  }

  // "Copy post": the ready-made caption, for Instagram, TikTok and the rest.
  async caption({ params: { caption } }) {
    try { await navigator.clipboard.writeText(caption) } catch { return }
    this.captionButtonTarget.textContent = "Copied!"
    setTimeout(() => { this.captionButtonTarget.textContent = "Copy post" }, 2000)
    this.count("caption")
  }

  // A picture or video card was shared (share_card_controller.js).
  counted({ detail: { channel } }) {
    this.count(channel)
  }

  select() {
    this.linkTarget.select()
  }

  // Text it / Email it: count it, and let the link open the app.
  record({ params: { channel } }) {
    this.count(channel)
  }

  async count(channel) {
    const body = new FormData()
    body.append("channel", channel)
    try {
      const response = await fetch(this.recordUrlValue, { method: "POST", body, keepalive: true })
      const { count } = await response.json()
      if (response.ok) this.celebrate(count)
    } catch (error) {
      // The share still happened; the counter just missed it.
    }
  }

  celebrate(count) {
    this.thanksTarget.textContent = `Thanks for spreading the love! That's share #${count.toLocaleString()}.`
    this.thanksTarget.classList.remove("hidden")
    const still = matchMedia("(prefers-reduced-motion: reduce)").matches
    document.querySelectorAll("[data-love-count]").forEach((el) => {
      el.textContent = count.toLocaleString()
      if (!still) el.animate?.([{ transform: "scale(1.4)", color: "#f2d826" }, { transform: "scale(1)" }], { duration: 600, easing: "ease-out" })
    })
  }
}
