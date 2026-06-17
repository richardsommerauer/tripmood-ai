import { Controller } from "@hotwired/stimulus"

// Makes the chat feel live while the AI thinks:
// - optimistically shows the user's message right away
// - shows a typing indicator until the assistant reply streams in
// (The Send button's "Thinking…" label is handled by Turbo via
//  data-turbo-submits-with, so we don't touch the button here.)
export default class extends Controller {
  static targets = ["input"]

  start() {
    const text = this.hasInputTarget ? this.inputTarget.value.trim() : ""
    if (!text && !this.hasFile()) return

    if (text) this.appendUserBubble(text)
    this.showTyping()
    if (this.hasInputTarget) this.inputTarget.value = ""
  }

  end() {
    this.removeTyping()
  }

  hasFile() {
    const file = this.element.querySelector('input[type="file"]')
    return file && file.files && file.files.length > 0
  }

  messagesEl() {
    return document.getElementById("messages")
  }

  appendUserBubble(text) {
    document.getElementById("empty-state")?.remove()
    const el = document.createElement("div")
    el.className = "msg msg-user"
    el.textContent = text
    this.messagesEl()?.appendChild(el)
  }

  showTyping() {
    if (document.getElementById("typing")) return
    const el = document.createElement("div")
    el.id = "typing"
    el.className = "msg msg-assistant msg-typing"
    el.innerHTML =
      '<span class="typing-dot"></span><span class="typing-dot"></span><span class="typing-dot"></span>'
    this.messagesEl()?.appendChild(el)
  }

  removeTyping() {
    document.getElementById("typing")?.remove()
  }
}
