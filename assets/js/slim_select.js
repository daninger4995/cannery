import SlimSelect from 'slim-select'

export default {
  initalizeSlimSelect (el) {
    // eslint-disable-next-line no-new
    el.slimselect = new SlimSelect({ select: el })

    const main = document.querySelector(`.ss-main[data-id="${el.dataset.id}"]`)
    main.setAttribute('id', `${el.dataset.id}-main`)
    main.setAttribute('phx-update', 'ignore')

    const content = document.querySelector(`.ss-content[data-id="${el.dataset.id}"]`)
    content.setAttribute('id', `${el.dataset.id}-content`)
    content.setAttribute('phx-update', 'ignore')
  },
  updated () {
    this.el.slimselect?.destroy()
    this.initalizeSlimSelect(this.el)
  },
  mounted () {
    this.initalizeSlimSelect(this.el)
  }
}
