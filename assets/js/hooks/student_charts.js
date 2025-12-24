// Student dashboard charts hook
export default {
  mounted() {
    this.initCharts()
    this.updateFromDataset()
  },
  // updated() {
  //   this.updateFromDataset()
  // },
  initCharts() {
    const Chart = window.Chart
    if (!Chart) return

    const attendanceTrendCtx = document.getElementById('attendanceTrendChart')?.getContext('2d')
    const courseDistCtx = document.getElementById('courseDistChart')?.getContext('2d')

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
  },
  updateFromDataset() {
    const el = this.el
    try {
      const attendanceLabels = JSON.parse(el.dataset.attendanceLabels || '[]')
      const attendanceCounts = JSON.parse(el.dataset.attendanceCounts || '[]')
      const courseLabels = JSON.parse(el.dataset.courseLabels || '[]')
      const courseCounts = JSON.parse(el.dataset.courseCounts || '[]')

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
    } catch (e) {
      console.warn('StudentCharts parse/update error', e)
    }
  }
}
