// Statistical charts hook
export default {
  mounted() {
    console.log('StatsCharts mounted - initializing charts')
    this.lastDataHash = null
    this.initCharts()
    this.updateFromDataset()
  },
  updated() {
    console.log('StatsCharts updated - checking if data changed')
    this.updateFromDataset()
  },
  destroyed() {
    console.log('StatsCharts destroyed - cleaning up charts')
    this.cleanupCharts()
  },
  cleanupCharts() {
    // Destroy only stats chart instances (not attendance charts)
    const charts = [
      'progChart', 'usersChart', 'otpChart', 'qrChart'
    ]
    
    charts.forEach(chartName => {
      if (this[chartName]) {
        console.log(`Destroying ${chartName}`)
        this[chartName].destroy()
        this[chartName] = null
      }
    })
  },
  initCharts() {
    const Chart = window.Chart
    if (!Chart) {
      console.error('Chart.js not available')
      return
    }

    console.log('Initializing StatsCharts...')
    
    const progCtx = document.getElementById('progBarChart')?.getContext('2d')
    const usersCtx = document.getElementById('usersLineChart')?.getContext('2d')
    const otpCtx = document.getElementById('otpDonutChart')?.getContext('2d')
    const qrCtx = document.getElementById('qrDonutChart')?.getContext('2d')

    console.log('Chart contexts found:', {
      progCtx: !!progCtx,
      usersCtx: !!usersCtx, 
      otpCtx: !!otpCtx,
      qrCtx: !!qrCtx
    })

    if (progCtx && !this.progChart) {
      // Check if Chart.js instance already exists on this canvas
      const existingChart = Chart.getChart(progCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing progChart instance')
        existingChart.destroy()
      }
      
      this.progChart = new Chart(progCtx, {
        type: 'bar',
        data: { labels: [], datasets: [{ label: 'Students', data: [], backgroundColor: '#3B82F6' }]},
        options: { responsive: true, animation: false, plugins: {legend: {display: false}}, scales: { y: { beginAtZero: true } } }
      })
    }
    if (usersCtx && !this.usersChart) {
      const existingChart = Chart.getChart(usersCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing usersChart instance')
        existingChart.destroy()
      }
      
      this.usersChart = new Chart(usersCtx, {
        type: 'line',
        data: { labels: [], datasets: [{ label: 'New Users', data: [], borderColor: '#10B981', backgroundColor: 'rgba(16,185,129,0.1)', tension: 0.3, fill: true }]},
        options: { responsive: true, animation: false, scales: { y: { beginAtZero: true } } }
      })
    }
    if (otpCtx && !this.otpChart) {
      const existingChart = Chart.getChart(otpCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing otpChart instance')
        existingChart.destroy()
      }
      
      this.otpChart = new Chart(otpCtx, {
        type: 'doughnut',
        data: { labels: ['Active', 'Inactive'], datasets: [{ data: [0, 0], backgroundColor: ['#3B82F6', '#E5E7EB'] }]},
        options: { responsive: true, animation: false, plugins: {legend: {position: 'bottom'}} }
      })
    }
    if (qrCtx && !this.qrChart) {
      const existingChart = Chart.getChart(qrCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing qrChart instance')
        existingChart.destroy()
      }
      
      this.qrChart = new Chart(qrCtx, {
        type: 'doughnut',
        data: { labels: ['Active/Valid', 'Expired'], datasets: [{ data: [0, 0], backgroundColor: ['#8B5CF6', '#F59E0B'] }]},
        options: { responsive: true, animation: false, plugins: {legend: {position: 'bottom'}} }
      })
    }
  },
  updateFromDataset() {
    const el = this.el
    console.log('Updating StatsCharts from dataset...')
    
    try {
      const progLabels = JSON.parse(el.dataset.progLabels || '[]')
      const progCounts = JSON.parse(el.dataset.progCounts || '[]')
      const usersLabels = JSON.parse(el.dataset.usersLabels || '[]')
      const usersCounts = JSON.parse(el.dataset.usersCounts || '[]')
      const otpsActive = parseInt(el.dataset.otpsActive || '0', 10)
      const otpsInactive = parseInt(el.dataset.otpsInactive || '0', 10)
      const qrActive = parseInt(el.dataset.qrActive || '0', 10)
      const qrExpired = parseInt(el.dataset.qrExpired || '0', 10)

      // Create a hash of the data to detect changes
      const currentDataHash = JSON.stringify({
        progLabels, progCounts, usersLabels, usersCounts,
        otpsActive, otpsInactive, qrActive, qrExpired
      })

      // Only update charts if data actually changed
      if (this.lastDataHash === currentDataHash) {
        console.log('StatsCharts data unchanged, skipping update')
        return
      }

      console.log('StatsCharts data changed, updating charts')
      this.lastDataHash = currentDataHash

      if (this.progChart) {
        this.progChart.data.labels = progLabels
        this.progChart.data.datasets[0].data = progCounts
        this.progChart.update('none') // Use 'none' for instant, no-animation updates
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
