import { Controller } from "@hotwired/stimulus"

// "Make a picture" / "Make a video": a story-size (1080×1920) JeeSauce card
// for this store, drawn on the shopper's phone (nothing made on our server):
// the logo, "I found it!", the store's flavor lids, the store and where, and
// findjeesauce.com. The video is the same card animated for 6 seconds,
// recorded from the canvas (MP4 where the browser can, else WebM).
// Sharing goes through the phone's share sheet (Instagram, TikTok, …) with
// the caption copied first, since most apps drop shared text; elsewhere the
// file downloads. Each finished share is counted ("picture" / "video").
const W = 1080
const H = 1920
const SECONDS = 6
const CREAM = "#fbf8f1"
const INK = "#000000"
const TEAL = "#1badcf"
const HALO = "#f2d826"
const MUTED = "#55524c"

export default class extends Controller {
  static targets = ["preview", "status", "video", "actions"]
  static values = { name: String, place: String, address: String, lids: Array, logo: String, caption: String, fileName: String }

  connect() {
    this.videoTarget.hidden = !(window.MediaRecorder && HTMLCanvasElement.prototype.captureStream)
  }

  async picture() {
    this.say("Making your picture…")
    const canvas = await this.canvas()
    this.draw(canvas.getContext("2d"), SECONDS) // the last frame: everything in place
    const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"))
    this.offer(new File([blob], `${this.fileNameValue}.png`, { type: "image/png" }), "picture", canvas.toDataURL("image/png"))
  }

  async video() {
    const type = ["video/mp4;codecs=avc1", "video/mp4", "video/webm;codecs=vp9", "video/webm"].find((t) => MediaRecorder.isTypeSupported(t))
    if (!type) return this.say("This browser can't make videos. Try “Make a picture”.")

    const canvas = await this.canvas()
    const ctx = canvas.getContext("2d")
    const recorder = new MediaRecorder(canvas.captureStream(30), { mimeType: type, videoBitsPerSecond: 6_000_000 })
    const chunks = []
    recorder.ondataavailable = (event) => event.data.size && chunks.push(event.data)
    const done = new Promise((resolve) => { recorder.onstop = resolve })

    recorder.start()
    const start = performance.now()
    await new Promise((resolve) => {
      const frame = (now) => {
        const t = (now - start) / 1000
        this.draw(ctx, t)
        this.say(`Making your video… ${Math.max(0, Math.ceil(SECONDS - t))}`)
        t < SECONDS ? requestAnimationFrame(frame) : resolve()
      }
      requestAnimationFrame(frame)
    })
    recorder.stop()
    await done

    const ext = type.startsWith("video/mp4") ? "mp4" : "webm"
    const blob = new Blob(chunks, { type: type.split(";")[0] })
    this.offer(new File([blob], `${this.fileNameValue}.${ext}`, { type: blob.type }), "video", URL.createObjectURL(blob), true)
  }

  // Share sheet when the phone can share files; otherwise a download.
  async offer(file, channel, previewUrl, isVideo = false) {
    this.previewTarget.replaceChildren(Object.assign(document.createElement(isVideo ? "video" : "img"), {
      src: previewUrl, alt: "Your JeeSauce card", className: "mt-2 max-h-72 rounded-xl", ...(isVideo ? { autoplay: true, loop: true, muted: true, playsInline: true } : {})
    }))
    try { await navigator.clipboard.writeText(this.captionValue) } catch { /* fine: the caption is on the page too */ }

    if (navigator.canShare?.({ files: [file] })) {
      this.say("Caption copied. Pick Instagram, TikTok or anywhere, then paste the caption.")
      const button = Object.assign(document.createElement("button"), {
        type: "button", textContent: isVideo ? "Share video…" : "Share picture…",
        className: "mt-2 rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-teal-dark"
      })
      // Share needs a fresh tap (making the file used up the first one).
      button.addEventListener("click", async () => {
        try {
          await navigator.share({ files: [file], text: this.captionValue })
          this.dispatch("shared", { detail: { channel } })
        } catch { /* closed the sheet */ }
      })
      this.actionsTarget.replaceChildren(button)
    } else {
      const link = Object.assign(document.createElement("a"), {
        href: URL.createObjectURL(file), download: file.name, textContent: isVideo ? "Download video" : "Download picture",
        className: "mt-2 inline-block rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-teal-dark"
      })
      link.addEventListener("click", () => this.dispatch("shared", { detail: { channel } }), { once: true })
      this.actionsTarget.replaceChildren(link)
      this.say("Caption copied. Download it, then post it with the caption.")
    }
  }

  async canvas() {
    await Promise.all(["800 120px Archivo", "700 70px Archivo", "40px Questrial"].map((f) => document.fonts.load(f)))
    this.images ||= await Promise.all([this.logoValue, ...this.lidsValue].map((src) => new Promise((resolve) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = () => resolve(null)
      img.src = src
    })))
    return Object.assign(document.createElement("canvas"), { width: W, height: H })
  }

  // One frame at t seconds. Everything eases in during the first ~3s, then
  // the lids keep a gentle bob so the video doesn't sit still.
  draw(ctx, t) {
    const [logo, ...lids] = this.images
    const ease = (from, len) => { const x = Math.min(Math.max((t - from) / len, 0), 1); return 1 - Math.pow(1 - x, 3) }
    const pop = (from) => { const x = Math.min(Math.max((t - from) / 0.5, 0), 1); return x === 0 ? 0 : 1 + 2.7 * Math.pow(x - 1, 3) + 1.7 * Math.pow(x - 1, 2) }

    ctx.fillStyle = CREAM
    ctx.fillRect(0, 0, W, H)
    const glow = ctx.createRadialGradient(W * 0.2, 0, 0, W * 0.2, 0, 1100)
    glow.addColorStop(0, "rgba(27,173,207,0.28)")
    glow.addColorStop(1, "rgba(27,173,207,0)")
    ctx.fillStyle = glow
    ctx.fillRect(0, 0, W, H)

    ctx.textAlign = "center"
    ctx.globalAlpha = ease(0, 0.6)
    if (logo) { const w = 300, h = w * logo.height / logo.width; ctx.drawImage(logo, (W - w) / 2, 100, w, h) }

    ctx.globalAlpha = ease(0.4, 0.5)
    ctx.save()
    ctx.translate(W / 2, 640)
    const s = pop(0.4) || 0.001
    ctx.scale(s, s)
    ctx.fillStyle = INK
    ctx.font = "800 150px Archivo"
    ctx.fillText("I found it!", 0, 0)
    ctx.restore()

    ctx.globalAlpha = 1
    const size = lids.length > 3 ? 210 : 280
    const perRow = lids.length > 3 ? 3 : lids.length
    lids.forEach((lid, i) => {
      if (!lid) return
      const row = Math.floor(i / perRow)
      const inRow = Math.min(perRow, lids.length - row * perRow)
      const x = W / 2 + (i % perRow - (inRow - 1) / 2) * (size + 50)
      const y = 780 + row * (size + 30) + size / 2 + Math.sin(t * 3 + i) * 10 * ease(2.5, 1)
      const k = pop(1 + i * 0.15)
      if (!k) return
      ctx.save()
      ctx.translate(x, y)
      ctx.rotate(Math.sin(t * 2 + i) * 0.06 * ease(2.5, 1))
      ctx.scale(k, k)
      ctx.shadowColor = "rgba(0,0,0,0.25)"
      ctx.shadowBlur = 24
      ctx.shadowOffsetY = 8
      ctx.drawImage(lid, -size / 2, -size / 2, size, size)
      ctx.restore()
    })

    const textTop = 780 + Math.ceil(lids.length / perRow) * (size + 30) + 50
    ctx.globalAlpha = ease(1.8, 0.6)
    const rise = (1 - ease(1.8, 0.6)) * 40
    ctx.fillStyle = MUTED
    ctx.font = "40px Questrial"
    ctx.fillText("at", W / 2, textTop + rise)
    ctx.fillStyle = INK
    ctx.font = "700 76px Archivo"
    const nameLines = this.wrap(ctx, this.nameValue, W - 140).slice(0, 2)
    nameLines.forEach((line, i) => ctx.fillText(line, W / 2, textTop + 90 + i * 88 + rise))
    ctx.fillStyle = MUTED
    ctx.font = "44px Questrial"
    this.wrap(ctx, this.addressValue, W - 160).slice(0, 2)
      .forEach((line, i) => ctx.fillText(line, W / 2, textTop + 110 + nameLines.length * 88 + i * 56 + rise))

    ctx.globalAlpha = ease(2.4, 0.6)
    const pillY = H - 230
    ctx.fillStyle = INK
    this.roundRect(ctx, 110, pillY, W - 220, 150, 75)
    ctx.fillStyle = HALO
    ctx.font = "700 40px Archivo"
    ctx.fillText("Find one near you", W / 2, pillY + 60)
    ctx.fillStyle = "#ffffff"
    ctx.font = "800 58px Archivo"
    ctx.fillText("findjeesauce.com", W / 2, pillY + 120)
    ctx.globalAlpha = 1
    ctx.fillStyle = TEAL
    ctx.fillRect(0, H - 24, W, 24)
  }

  wrap(ctx, text, width) {
    const lines = []
    let line = ""
    for (const word of text.split(/\s+/)) {
      const next = line ? `${line} ${word}` : word
      if (ctx.measureText(next).width > width && line) { lines.push(line); line = word } else line = next
    }
    if (line) lines.push(line)
    return lines
  }

  roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath()
    ctx.roundRect ? ctx.roundRect(x, y, w, h, r) : ctx.rect(x, y, w, h)
    ctx.fill()
  }

  say(text) {
    this.statusTarget.textContent = text
    this.statusTarget.hidden = !text
  }
}
