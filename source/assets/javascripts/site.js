import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

document.addEventListener('DOMContentLoaded', function (event) {
  const images = document.querySelectorAll("img")
  images.forEach((image) => {
    if (image.offsetWidth > 0) {
      image.setAttribute("sizes", `${image.offsetWidth}px`)
    }
  })
})
