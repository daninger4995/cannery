// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Theme toggle (light/dark mode)
function getStoredTheme() {
  return localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
}

function applyTheme(theme) {
  document.documentElement.classList.toggle('dark', theme === 'dark')
}

// Apply theme immediately to prevent flash
applyTheme(getStoredTheme())

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import Date from './date'
import DateTime from './datetime'
import ShotLogChart from './shot_log_chart'
import SlimSelect from './slim_select'
import topbar from 'topbar'
import { hooks as colocatedHooks } from 'phoenix-colocated/cannery'

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { Date, DateTime, ShotLogChart, SlimSelect, ...colocatedHooks }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', info => topbar.show())
window.addEventListener('phx:page-loading-stop', info => {
  topbar.hide()
  applyTheme(getStoredTheme())
})
window.addEventListener('submit', info => topbar.show())
window.addEventListener('beforeunload', info => topbar.show())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Copy to clipboard
window.addEventListener('cannery:clipcopy', (event) => {
  if ('clipboard' in navigator) {
    const text = event.target.textContent
    navigator.clipboard.writeText(text)
  } else {
    window.alert('Sorry, your browser does not support clipboard copy.')
  }
})

// Set input value to 0
window.addEventListener('cannery:set-zero', (event) => {
  event.target.value = 0
})
