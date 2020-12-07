import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import Turbolinks from "turbolinks"

Turbolinks.start()

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

function setImageSizes() {
  const images = document.querySelectorAll("img")
  images.forEach((image) => {
    if (image.offsetWidth > 0) {
      image.setAttribute("sizes", `${image.offsetWidth}px`)
    }
  })
}

document.addEventListener("turbolinks:load", setImageSizes)
document.addEventListener('DOMContentLoaded', setImageSizes)
