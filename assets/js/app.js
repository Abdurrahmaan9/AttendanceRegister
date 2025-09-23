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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Import Alpine.js
import Alpine from 'alpinejs'

// Initialize Alpine.js
window.Alpine = Alpine
Alpine.start()

// Import QR Scanner
import { QRScanner } from "./qr_scanner"

// Import Sidebar Dropdowns
import "./sidebar_dropdowns"

// Import background carousels
import bgCarousel from "./bg_carousel"

// Import student actions
import "./student_actions"

// Import modal functionality
import "./modal"

// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Get CSRF token for secure requests
let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

// Initialize LiveSocket with hooks
let hooks = {
  // Register QRScanner hook
  QRScanner: QRScanner,
  
  // Register background carousel hooks
  BgCarousel: bgCarousel,
  LocalBgCarousel: localBgCarousel
};

// Create LiveSocket instance with hooks
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
  dom: {
    // Add any custom DOM handling here
  },
  // Enable debug mode in development
  // debug: process.env.NODE_ENV === 'development',
  // Enable latency simulation for testing
  // latencySim: process.env.NODE_ENV === 'development' ? 1000 : 0,
  // Long polling fallback in case of WebSocket issues
  longPollFallbackMs: 2500
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

