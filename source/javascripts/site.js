document.addEventListener('DOMContentLoaded', function (event) {
  const images = document.querySelectorAll(".ScaledImage img")
  images.forEach((image) => {
    image.setAttribute("sizes", `${image.offsetWidth}px`)
  })
})
