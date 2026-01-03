// System performance charts hook
export default {
  mounted() {
    console.log('SystemCharts mounted - initializing system charts')
    this.lastDataHash = null
    this.wasLoading = true
    this.initCharts()
    this.updateFromDataset()
  },
  updated() {
    console.log('SystemCharts updated - checking if data changed')
    const el = this.el
    const isLoading = el.dataset.loading === 'true'
    
    console.log('SystemCharts loading state:', { isLoading, wasLoading: this.wasLoading })
    
    // If loading just completed, reinitialize charts with a delay to ensure DOM is ready
    if (!isLoading && this.wasLoading) {
      console.log('SystemCharts loading completed, reinitializing charts')
      // Add a small delay to ensure the canvas elements are rendered
      setTimeout(() => {
        this.initCharts()
        this.updateFromDataset()
      }, 100)
    }
    
    this.wasLoading = isLoading
    this.updateFromDataset()
  },
  destroyed() {
    console.log('SystemCharts destroyed - cleaning up system charts')
    this.cleanupCharts()
  },
  cleanupCharts() {
    // Destroy system chart instances
    const charts = ['memChart', 'runqChart', 'ioChart']
    
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
    console.log('Updating SystemCharts from dataset...')
    
    try {
      const labels = JSON.parse(el.dataset.labels || '[]')
      const mem = JSON.parse(el.dataset.memSeries || '[]')
      const runq = JSON.parse(el.dataset.runqSeries || '[]')
      const ioin = JSON.parse(el.dataset.ioinSeries || '[]')
      const ioout = JSON.parse(el.dataset.iooutSeries || '[]')

      // Create a hash of the data to detect changes
      const currentDataHash = JSON.stringify({
        labels, mem, runq, ioin, ioout
      })

      // Only update charts if data actually changed
      if (this.lastDataHash === currentDataHash) {
        console.log('SystemCharts data unchanged, skipping update')
        return
      }

      console.log('SystemCharts data changed, updating charts')
      this.lastDataHash = currentDataHash

      if (this.memChart) {
        this.memChart.data.labels = labels
        this.memChart.data.datasets[0].data = mem
        this.memChart.update('none') // Use 'none' for instant, no-animation updates
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
}
