import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("connected")
  }

  activate(event) {
    event.preventDefault();
    const index = event.params.index;

    this.element.querySelector(".step-headers .active").classList.remove("active");
    event.target.parentElement.classList.add("active")

    this.element.querySelector(".step-content:not(.hidden)").classList.add("hidden")
    this.element.querySelector(`.step-content:nth-child(${index})`).classList.remove("hidden")
  }

  next(event) {
    event.preventDefault();
    const header = this.element.querySelector(".step-headers .active")
    const content = this.element.querySelector(".step-content:not(.hidden)")

    header.nextElementSibling.classList.add("active")
    header.classList.remove("active")

    content.nextElementSibling.classList.remove("hidden")
    content.classList.add("hidden")
  }

  prev(event) {
    event.preventDefault();
    const header = this.element.querySelector(".step-headers .active")
    const content = this.element.querySelector(".step-content:not(.hidden)")

    header.previousElementSibling.classList.add("active")
    header.classList.remove("active")

    content.previousElementSibling.classList.remove("hidden")
    content.classList.add("hidden")
  }
}
