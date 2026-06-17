import { Controller } from "@hotwired/stimulus"

// Keeps the chat scrolled to the latest message: on load and after every
// Turbo Stream update (new bubbles appended to this element).
export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
