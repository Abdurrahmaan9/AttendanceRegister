// Attendance charts hook - dedicated for attendance-specific charts
export default {
  mounted() {
    console.log('AttendanceCharts mounted - initializing attendance charts')
    this.lastDataHash = null
    this.initCharts()
    this.updateFromDataset()
  },
  updated() {
    console.log('AttendanceCharts updated - checking if data changed')
    this.updateFromDataset()
  },
  destroyed() {
    console.log('AttendanceCharts destroyed - cleaning up attendance charts')
    this.cleanupCharts()
  },
  cleanupCharts() {
    // Destroy only attendance chart instances
    const charts = ['dailyChart', 'signinDistChart', 'weeklyTrendChart']
    
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

    console.log('Initializing AttendanceCharts...')
    
    const dailyCtx = document.getElementById('dailySigninsChart')?.getContext('2d')
    const signinDistCtx = document.getElementById('signinDistributionChart')?.getContext('2d')
    const weeklyTrendCtx = document.getElementById('weeklyTrendChart')?.getContext('2d')

    console.log('Attendance chart contexts found:', {
      dailyCtx: !!dailyCtx,
      signinDistCtx: !!signinDistCtx,
      weeklyTrendCtx: !!weeklyTrendCtx
    })

    if (dailyCtx && !this.dailyChart) {
      const existingChart = Chart.getChart(dailyCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing dailyChart instance')
        existingChart.destroy()
      }
      
      this.dailyChart = new Chart(dailyCtx, {
        type: 'line',
        data: {
          labels: [],
          datasets: [{
              label: 'QR Attendance',
              data: [],
              borderColor: '#3B82F6',
              backgroundColor: 'rgba(59, 130, 246, 0.1)',
              tension: 0.3,
              fill: true
            },
            {
              label: 'OTP Attendance',
              data: [],
              borderColor: '#8B5CF6',
              backgroundColor: 'rgba(139, 92, 246, 0.1)',
              tension: 0.3,
              fill: true
            }
          ]
        },
        options: {
          responsive: true,
          animation: false,
          interaction: {
            intersect: false,
            mode: 'index',
          },
          plugins: {
            legend: {
              position: 'top',
            },
            tooltip: {
              mode: 'index',
              intersect: false,
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                callback: function(value) {
                  return value + ' students';
                }
              }
            }
          }
        }
      })
    }
    if (signinDistCtx && !this.signinDistChart) {
      const existingChart = Chart.getChart(signinDistCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing signinDistChart instance')
        existingChart.destroy()
      }
      
      this.signinDistChart = new Chart(signinDistCtx, {
        type: 'doughnut',
        data: { 
          labels: [],
          datasets: [{
            data: [],
            backgroundColor: ['#3B82F6', '#10B981']
          }]
        },
        options: { 
          responsive: true,
          animation: false,
          interaction: {
            intersect: false,
            mode: 'index',
          },
          plugins: {
            legend: {
              position: 'bottom'
            },
            tooltip: {
              mode: 'index',
              intersect: false,
              callbacks: {
                label: function(context) {
                  const label = context.label || ''
                  const value = context.parsed || 0
                  const total = context.dataset.data.reduce((a, b) => a + b, 0)
                  const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
                  return `${label}: ${value} (${percentage}%)`
                }
              }
            }
          }
        }
      })
    }
    if (weeklyTrendCtx && !this.weeklyTrendChart) {
      const existingChart = Chart.getChart(weeklyTrendCtx.canvas)
      if (existingChart) {
        console.log('Destroying existing weeklyTrendChart instance')
        existingChart.destroy()
      }
      
      this.weeklyTrendChart = new Chart(weeklyTrendCtx, {
        type: 'bar',
        data: {
          labels: [],
          datasets: [{
            label: 'Attendance',
            data: [],
            backgroundColor: '#10B981',
          }]
        },
        options: {
          responsive: true,
          animation: false,
          interaction: {
            intersect: false,
            mode: 'index',
          },
          plugins: {
            legend: {
              position: 'top',
            },
            tooltip: {
              mode: 'index',
              intersect: false,
            }
          },
          scales: {
            x: {
              stacked: false,
            },
            y: {
              stacked: false,
              beginAtZero: true
            }
          }
        }
      })
    }
  },
  updateFromDataset() {
    const el = this.el
    console.log('Updating AttendanceCharts from dataset...')
    console.log('Available dataset attributes:', Object.keys(el.dataset))
    
    try {
      // Debug: Log raw dataset values
      console.log('Raw dataset values:', {
        signinQr: el.dataset.signinQr,
        signinOtp: el.dataset.signinOtp,
        signinLabels: el.dataset.signinLabels,
        weeklyTrendData: el.dataset.weeklyTrendData,
        weeklyTrendLabels: el.dataset.weeklyTrendLabels,
        dailyQrData: el.dataset.dailyQrData,
        dailyOtpData: el.dataset.dailyOtpData,
        dailyLabels: el.dataset.dailyLabels
      })

      const signinQr = parseInt(el.dataset.signinQr || '0', 10)
      const signinOtp = parseInt(el.dataset.signinOtp || '0', 10)
      const signinLabels = JSON.parse(el.dataset.signinLabels || '["QR Code", "OTP"]')
      const weeklyTrendData = JSON.parse(el.dataset.weeklyTrendData || '[]')
      const weeklyTrendLabels = JSON.parse(el.dataset.weeklyTrendLabels || '[]')
      const dailyQrData = JSON.parse(el.dataset.dailyQrData || '[]')
      const dailyOtpData = JSON.parse(el.dataset.dailyOtpData || '[]')
      const dailyLabels = JSON.parse(el.dataset.dailyLabels || '[]')

      console.log('Parsed attendance dataset values:', {
        signinQr, signinOtp, signinLabels,
        weeklyTrendData, weeklyTrendLabels,
        dailyQrData, dailyOtpData, dailyLabels
      })

      // Create a hash of the data to detect changes
      const currentDataHash = JSON.stringify({
        signinQr, signinOtp, signinLabels,
        weeklyTrendData, weeklyTrendLabels,
        dailyQrData, dailyOtpData, dailyLabels
      })

      // Only update charts if data actually changed
      if (this.lastDataHash === currentDataHash) {
        console.log('AttendanceCharts data unchanged, skipping update')
        return
      }

      console.log('AttendanceCharts data changed, updating charts')
      this.lastDataHash = currentDataHash

      if (this.signinDistChart) {
        console.log('Updating signinDistChart with:', [signinQr, signinOtp])
        this.signinDistChart.data.labels = signinLabels
        this.signinDistChart.data.datasets[0].data = [signinQr, signinOtp]
        this.signinDistChart.update('none') // Use 'none' for instant, no-animation updates
      }
      if (this.weeklyTrendChart) {
        console.log('Updating weeklyTrendChart with:', weeklyTrendData)
        this.weeklyTrendChart.data.labels = weeklyTrendLabels
        this.weeklyTrendChart.data.datasets[0].data = weeklyTrendData
        this.weeklyTrendChart.update('none')
      }
      if (this.dailyChart) {
        console.log('Updating dailyChart with:', { dailyLabels, dailyQrData, dailyOtpData })
        this.dailyChart.data.labels = dailyLabels
        this.dailyChart.data.datasets[0].data = dailyQrData
        this.dailyChart.data.datasets[1].data = dailyOtpData
        this.dailyChart.update('none')
      }
    } catch (e) {
      console.warn('AttendanceCharts parse/update error', e)
    }
  }
}
