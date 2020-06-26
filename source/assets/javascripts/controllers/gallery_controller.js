// gallery_controller.js
import { Controller } from 'stimulus'
import * as PhotoSwipe from 'photoswipe'
import * as PhotoSwipeUI_Default from 'photoswipe/dist/photoswipe-ui-default'

export default class extends Controller {
  static targets = ["picture"]

  onImageClick(event) {
    event.preventDefault()

    // as our gallery markup lives outside of our controller
    // unfortunately we need to query for it, for the simplicity of example
    // let's assume we have single gallery controller in the app and we can call
    // query selector directly by it's class and we don't need to extract it into
    // configurable data-attribute
    const galleryWrapper = document.querySelector('.pswp')
    const items = this.items
    var options = {
      // we don't want browser history for or example for the sake of simplicity
      history: false,
      // and I'm assuming we have unique links in each gallery
      index: items.findIndex(item => item.src === event.currentTarget.getAttribute('href'))
    }

    var gallery = new PhotoSwipe(galleryWrapper, PhotoSwipeUI_Default, items, options)

    // PhotoSwipe requires width and height do be declared up-front
    // let's work around that limitation, references:
    // https://github.com/dimsemenov/PhotoSwipe/issues/741#issuecomment-430725838
    gallery.listen('beforeChange', function() {
      const src = gallery.currItem.src

      const image = new Image()
      image.src = src

      image.onload = () => {
        gallery.currItem.w = image.width
        gallery.currItem.h = image.height

        gallery.updateSize()
      }
    })

    gallery.init()
  }

  get items() {
    return this.pictureTargets.map(function(item) {
      return {
        src: item.getAttribute('href'),
        title: item.getAttribute('title'),
        w: 0,
        h: 0
      }
    })
  }
}
