// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Import dependencies
import Chart from "chart.js/auto"
import { QRScanner } from "./qr_scanner_bk"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Make Chart available globally for existing hooks
window.Chart = Chart

// Import application modules
import "./sidebar_dropdowns"
import bgCarousel from "./bg_carousel"
import "./student_actions"
import "./modal"
import StudentCharts from "./hooks/student_charts"
import SystemCharts from "./hooks/system_charts"
import StatsCharts from "./hooks/stats_charts"
import AttendanceCharts from "./hooks/attendance_charts"
import { AdminDashboardCharts } from "./hooks/admin_dashboard_charts"


// Get CSRF token for secure requests
let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

// Initialize all hooks in one place
let hooks = {
  // Register QRScanner hook
  QRScanner: QRScanner,
  
  // Register background carousel hooks
  BgCarousel: bgCarousel,

  // System performance charts hook
  SystemCharts: SystemCharts,
  
  // Statistical charts hook
  StatsCharts: StatsCharts,

  // Attendance charts hook
  AttendanceCharts: AttendanceCharts,

  // Student dashboard charts hook
  StudentCharts: StudentCharts,

  // Admin dashboard charts hook
  AdminDashboardCharts: AdminDashboardCharts,
}

// Create and initialize LiveSocket instance with all hooks
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks, // <-- FIXED: Use the hooks object directly, no spreading or duplicates
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