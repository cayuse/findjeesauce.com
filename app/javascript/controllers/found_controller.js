import { Controller } from "@hotwired/stimulus"

// "I found it!": shrinks the photo to a 1600px JPEG in the browser before it
// is sent (phones' HEIC/PNG become JPEG; the file gets small), and asks for
// the OK box when there's a photo. The server strips metadata either way.
const MAX_SIDE = 1600

export default class extends Controller {
  static targets = ["photo", "preview", "ok", "message", "submit"]

  async picked() {
    this.say("")
    this.jpeg = null
    const file = this.photoTarget.files[0]
    if (!file) return this.previewTarget.hidden = true

    try {
      const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
      const scale = Math.min(1, MAX_SIDE / Math.max(bitmap.width, bitmap.height))
      const canvas = document.createElement("canvas")
      canvas.width = Math.round(bitmap.width * scale)
      canvas.height = Math.round(bitmap.height * scale)
      canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height)
      this.jpeg = await new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.82))
      this.previewTarget.src = URL.createObjectURL(this.jpeg)
      this.previewTarget.hidden = false
    } catch (error) {
      this.say("We couldn't read that photo. Try another, or send it without one.")
    }
  }

  submit(event) {
    if (!this.hasPhotoTarget) return // photos are switched off (Sighting.photos?)
    const hasPhoto = this.photoTarget.files.length > 0
    if (hasPhoto && !this.okTarget.checked) {
      event.preventDefault()
      return this.say("Tick the box to send your photo, or remove it.")
    }
    if (!hasPhoto || !this.jpeg) return // no photo, or no canvas: the form posts as-is

    const transfer = new DataTransfer()
    transfer.items.add(new File([this.jpeg], "found.jpg", { type: "image/jpeg" }))
    this.photoTarget.files = transfer.files
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Sending…"
  }

  say(text) {
    if (!this.hasMessageTarget) return
    this.messageTarget.textContent = text
    this.messageTarget.hidden = !text
  }
}
