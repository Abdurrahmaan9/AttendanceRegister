// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Import dependencies
import { QRScanner } from "./qr_scanner_bk"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Import application modules
import "./sidebar_dropdowns"
import bgCarousel from "./bg_carousel"
import "./student_actions"
import "./modal"


// Get CSRF token for secure requests
let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

// Initialize all hooks in one place
let hooks = {
  // Register QRScanner hook
  QRScanner: QRScanner,
  
  // Register background carousel hooks
  BgCarousel: bgCarousel,

  // System performance charts hook
  SystemCharts: {
    mounted() {
      this.initCharts()
      this.updateFromDataset()
    },
    updated() {
      this.updateFromDataset()
    },
    initCharts() {
      const Chart = window.Chart
      if (!Chart) return

      const memCtx = document.getElementById('systemMemChart')?.getContext('2d')
      const runqCtx = document.getElementById('systemRunqChart')?.getContext('2d')
      const ioCtx = document.getElementById('systemIOChart')?.getContext('2d')

      if (memCtx && !this.memChart) {
        this.memChart = new Chart(memCtx, {
          type: 'line',
          data: { labels: [], datasets: [{ label: 'Memory (MB)', data: [], borderColor: '#3B82F6', backgroundColor: 'rgba(59, 130, 246, 0.1)', tension: 0.3, fill: true }]},
          options: { responsive: true, animation: false, scales: { y: { beginAtZero: true } } }
        })
      }
      if (runqCtx && !this.runqChart) {
        this.runqChart = new Chart(runqCtx, {
          type: 'line',
          data: { labels: [], datasets: [{ label: 'Run Queue', data: [], borderColor: '#F59E0B', backgroundColor: 'rgba(245, 158, 11, 0.1)', tension: 0.3, fill: true }]},
          options: { responsive: true, animation: false, scales: { y: { beginAtZero: true } } }
        })
      }
      if (ioCtx && !this.ioChart) {
        this.ioChart = new Chart(ioCtx, {
          type: 'line',
          data: { labels: [], datasets: [
            { label: 'IO In (KB/s)', data: [], borderColor: '#10B981', backgroundColor: 'rgba(16,185,129,0.1)', tension: 0.3, fill: true },
            { label: 'IO Out (KB/s)', data: [], borderColor: '#8B5CF6', backgroundColor: 'rgba(139,92,246,0.1)', tension: 0.3, fill: true }
          ]},
          options: { responsive: true, animation: false, scales: { y: { beginAtZero: true } } }
        })
      }
    },
    updateFromDataset() {
      const el = this.el
      try {
        const labels = JSON.parse(el.dataset.labels || '[]')
        const mem = JSON.parse(el.dataset.memSeries || '[]')
        const runq = JSON.parse(el.dataset.runqSeries || '[]')
        const ioin = JSON.parse(el.dataset.ioinSeries || '[]')
        const ioout = JSON.parse(el.dataset.iooutSeries || '[]')

        if (this.memChart) {
          this.memChart.data.labels = labels
          this.memChart.data.datasets[0].data = mem
          this.memChart.update('none')
        }
        if (this.runqChart) {
          this.runqChart.data.labels = labels
          this.runqChart.data.datasets[0].data = runq
          this.runqChart.update('none')
        }
        if (this.ioChart) {
          this.ioChart.data.labels = labels
          this.ioChart.data.datasets[0].data = ioin
          this.ioChart.data.datasets[1].data = ioout
          this.ioChart.update('none')
        }
      } catch (e) {
        console.warn('SystemCharts parse/update error', e)
      }
    }
  },
  
  // Statistical charts hook
  StatsCharts: {
    mounted() {
      this.initCharts()
      this.updateFromDataset()
    },
    updated() {
      this.updateFromDataset()
    },
    initCharts() {
      const Chart = window.Chart
      if (!Chart) return

      const progCtx = document.getElementById('progBarChart')?.getContext('2d')
      const usersCtx = document.getElementById('usersLineChart')?.getContext('2d')
      const otpCtx = document.getElementById('otpDonutChart')?.getContext('2d')
      const qrCtx = document.getElementById('qrDonutChart')?.getContext('2d')

      if (progCtx && !this.progChart) {
        this.progChart = new Chart(progCtx, {
          type: 'bar',
          data: { labels: [], datasets: [{ label: 'Students', data: [], backgroundColor: '#3B82F6' }]},
          options: { responsive: true, animation: false, plugins: {legend: {display: false}}, scales: { y: { beginAtZero: true } } }
        })
      }
      if (usersCtx && !this.usersChart) {
        this.usersChart = new Chart(usersCtx, {
          type: 'line',
          data: { labels: [], datasets: [{ label: 'New Users', data: [], borderColor: '#10B981', backgroundColor: 'rgba(16,185,129,0.1)', tension: 0.3, fill: true }]},
          options: { responsive: true, animation: false, scales: { y: { beginAtZero: true } } }
        })
      }
      if (otpCtx && !this.otpChart) {
        this.otpChart = new Chart(otpCtx, {
          type: 'doughnut',
          data: { labels: ['Active', 'Inactive'], datasets: [{ data: [0, 0], backgroundColor: ['#3B82F6', '#E5E7EB'] }]},
          options: { responsive: true, animation: false, plugins: {legend: {position: 'bottom'}} }
        })
      }
      if (qrCtx && !this.qrChart) {
        this.qrChart = new Chart(qrCtx, {
          type: 'doughnut',
          data: { labels: ['Active/Valid', 'Expired'], datasets: [{ data: [0, 0], backgroundColor: ['#8B5CF6', '#F59E0B'] }]},
          options: { responsive: true, animation: false, plugins: {legend: {position: 'bottom'}} }
        })
      }
    },
    updateFromDataset() {
      const el = this.el
      try {
        const progLabels = JSON.parse(el.dataset.progLabels || '[]')
        const progCounts = JSON.parse(el.dataset.progCounts || '[]')
        const usersLabels = JSON.parse(el.dataset.usersLabels || '[]')
        const usersCounts = JSON.parse(el.dataset.usersCounts || '[]')
        const otpsActive = parseInt(el.dataset.otpsActive || '0', 10)
        const otpsInactive = parseInt(el.dataset.otpsInactive || '0', 10)
        const qrActive = parseInt(el.dataset.qrActive || '0', 10)
        const qrExpired = parseInt(el.dataset.qrExpired || '0', 10)

        if (this.progChart) {
          this.progChart.data.labels = progLabels
          this.progChart.data.datasets[0].data = progCounts
          this.progChart.update('none')
        }
        if (this.usersChart) {
          this.usersChart.data.labels = usersLabels
          this.usersChart.data.datasets[0].data = usersCounts
          this.usersChart.update('none')
        }
        if (this.otpChart) {
          this.otpChart.data.datasets[0].data = [otpsActive, otpsInactive]
          this.otpChart.update('none')
        }
        if (this.qrChart) {
          this.qrChart.data.datasets[0].data = [qrActive, qrExpired]
          this.qrChart.update('none')
        }
      } catch (e) {
        console.warn('StatsCharts parse/update error', e)
      }
    }
  }
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