document.addEventListener('DOMContentLoaded', function (event) {
  const images = document.querySelectorAll(".ScaledImage img")
  images.forEach((image) => {
    if (image.offsetWidth > 0) {
      image.setAttribute("sizes", `${image.offsetWidth}px`)
    }
  })
})
