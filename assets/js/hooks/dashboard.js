import Chart from "chart.js/auto";

// Hook for the Lecturer Dashboard - System Performance Charts
export const SystemCharts = {
  mounted() {
    this.initCharts()
    this.updateFromDataset()
  },
  // updated() {
  //   this.updateFromDataset()
  // },
  initCharts() {
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
      const memData = JSON.parse(el.dataset.memSeries || '[]')
      const runqData = JSON.parse(el.dataset.runqSeries || '[]')
      const ioInData = JSON.parse(el.dataset.ioinSeries || '[]')
      const ioOutData = JSON.parse(el.dataset.iooutSeries || '[]')

      if (this.memChart) {
        this.memChart.data.labels = labels
        this.memChart.data.datasets[0].data = memData
        this.memChart.update('none')
      }
      if (this.runqChart) {
        this.runqChart.data.labels = labels
        this.runqChart.data.datasets[0].data = runqData
        this.runqChart.update('none')
      }
      if (this.ioChart) {
        this.ioChart.data.labels = labels
        this.ioChart.data.datasets[0].data = ioInData
        this.ioChart.data.datasets[1].data = ioOutData
        this.ioChart.update('none')
      }
    } catch (e) {
      console.warn('SystemCharts parse/update error', e)
    }
  }
}

// Hook for the Student Dashboard - Enhanced Version
export const StudentCharts = {
  mounted() {
    this.initCharts()
    this.updateFromDataset()
  },
  updated() {
    this.updateFromDataset()
  },
  initCharts() {
    if (!Chart) return

    const attendanceTrendCtx = document.getElementById('attendanceTrendChart')?.getContext('2d')
    const courseDistCtx = document.getElementById('courseDistChart')?.getContext('2d')
    const signinDistCtx = document.getElementById('signinDistributionChart')?.getContext('2d')

    if (attendanceTrendCtx && !this.attendanceTrendChart) {
      this.attendanceTrendChart = new Chart(attendanceTrendCtx, {
        type: 'line',
        data: { 
          labels: [], 
          datasets: [{
            label: 'My Attendance',
            data: [],
            borderColor: '#3B82F6',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            tension: 0.3,
            fill: true
          }]
        },
        options: { 
          responsive: true,
          animation: false,
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                callback: function(value) {
                  return value + ' sessions';
                }
              }
            }
          }
        }
      })
    }

    if (courseDistCtx && !this.courseDistChart) {
      this.courseDistChart = new Chart(courseDistCtx, {
        type: 'doughnut',
        data: { 
          labels: [],
          datasets: [{
            data: [],
            backgroundColor: ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B']
          }]
        },
        options: { 
          responsive: true,
          animation: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          }
        }
      })
    }
    if (signinDistCtx && !this.signinDistChart) {
      this.signinDistChart = new Chart(signinDistCtx, {
        type: 'doughnut',
        data: { 
          labels: ['QR Code', 'OTP'],
          datasets: [{
            data: [0, 0],
            backgroundColor: ['#3B82F6', '#10B981']
          }]
        },
        options: { 
          responsive: true,
          animation: false,
          plugins: {
            legend: {
              position: 'bottom'
            },
            tooltip: {
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
  },
  updateFromDataset() {
    const el = this.el
    try {
      const attendanceLabels = JSON.parse(el.dataset.attendanceLabels || '[]')
      const attendanceCounts = JSON.parse(el.dataset.attendanceCounts || '[]')
      const courseLabels = JSON.parse(el.dataset.courseLabels || '[]')
      const courseCounts = JSON.parse(el.dataset.courseCounts || '[]')
      const signinQr = parseInt(el.dataset.signinQr || '0', 10)
      const signinOtp = parseInt(el.dataset.signinOtp || '0', 10)

      if (this.attendanceTrendChart) {
        this.attendanceTrendChart.data.labels = attendanceLabels
        this.attendanceTrendChart.data.datasets[0].data = attendanceCounts
        this.attendanceTrendChart.update('none')
      }
      if (this.courseDistChart) {
        this.courseDistChart.data.labels = courseLabels
        this.courseDistChart.data.datasets[0].data = courseCounts
        this.courseDistChart.update('none')
      }
      if (this.signinDistChart) {
        this.signinDistChart.data.datasets[0].data = [signinQr, signinOtp]
        this.signinDistChart.update('none')
      }
    } catch (e) {
      console.warn('StudentCharts parse/update error', e)
    }
  }
}

// Export both hooks for use in app.js
export default {
  SystemCharts,
  StudentCharts
}