document.addEventListener('DOMContentLoaded', function (event) {
  const images = document.querySelectorAll(".c--markdown__image")
  images.forEach((image) => {
    if (image.offsetWidth > 0) {
      image.setAttribute("sizes", `${image.offsetWidth}px`)
    }
  })
})
