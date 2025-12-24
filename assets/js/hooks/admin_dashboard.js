export const AdminDashboardCharts = {
  mounted() {
    console.log("Admin Dashboard Charts hook mounted");
    
    // Set current date
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    const currentDateElement = document.getElementById('current-date');
    if (currentDateElement) {
      currentDateElement.textContent = new Date().toLocaleDateString('en-US', options);
    }

    this.initializeCharts();
  },

  updated() {
    console.log("Admin Dashboard Charts hook updated");
    this.updateCharts();
  },

  initializeCharts() {
    // Daily Sign-ins Chart
    const dailySigninsCtx = document.getElementById('dailySigninsChart');
    if (dailySigninsCtx) {
      this.dailySigninsChart = new Chart(dailySigninsCtx.getContext('2d'), {
        type: 'line',
        data: {
          labels: ['6:00 AM', '8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM'],
          datasets: [
            {
              label: 'Students',
              data: [120, 450, 320, 180, 250, 150],
              borderColor: '#3B82F6',
              backgroundColor: 'rgba(59, 130, 246, 0.1)',
              tension: 0.3,
              fill: true
            },
            {
              label: 'Staff',
              data: [30, 120, 80, 40, 60, 30],
              borderColor: '#8B5CF6',
              backgroundColor: 'rgba(139, 92, 246, 0.1)',
              tension: 0.3,
              fill: true
            },
            {
              label: 'Lecturers',
              data: [15, 60, 40, 20, 30, 15],
              borderColor: '#10B981',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              tension: 0.3,
              fill: true
            }
          ]
        },
        options: {
          responsive: true,
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
                  return value;
                }
              }
            }
          }
        }
      });
    }

    // Sign-in Distribution Chart
    const signinDistributionCtx = document.getElementById('signinDistributionChart');
    if (signinDistributionCtx) {
      this.signinDistributionChart = new Chart(signinDistributionCtx.getContext('2d'), {
        type: 'doughnut',
        data: {
          labels: ['Students', 'Staff', 'Lecturers'],
          datasets: [{
            data: [780, 150, 102],
            backgroundColor: [
              '#3B82F6',
              '#8B5CF6',
              '#10B981'
            ],
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          plugins: {
            legend: {
              position: 'bottom',
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  const label = context.label || '';
                  const value = context.raw || 0;
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const percentage = Math.round((value / total) * 100);
                  return `${label}: ${value} (${percentage}%)`;
                }
              }
            }
          }
        }
      });
    }

    // Weekly Trend Chart
    const weeklyTrendCtx = document.getElementById('weeklyTrendChart');
    if (weeklyTrendCtx) {
      this.weeklyTrendChart = new Chart(weeklyTrendCtx.getContext('2d'), {
        type: 'bar',
        data: {
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          datasets: [
            {
              label: 'Students',
              data: [650, 720, 680, 740, 800, 150],
              backgroundColor: '#3B82F6',
            },
            {
              label: 'Staff',
              data: [120, 140, 130, 150, 160, 30],
              backgroundColor: '#8B5CF6',
            },
            {
              label: 'Lecturers',
              data: [80, 90, 85, 95, 100, 20],
              backgroundColor: '#10B981',
            }
          ]
        },
        options: {
          responsive: true,
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
      });
    }
  },

  updateCharts() {
    // This method can be used to update charts with new data
    // For now, charts are initialized with static data
    // In the future, this can be extended to update with dynamic data from the LiveView
  },

  destroyed() {
    console.log("Admin Dashboard Charts hook destroyed");
    
    // Clean up chart instances
    if (this.dailySigninsChart) {
      this.dailySigninsChart.destroy();
    }
    if (this.signinDistributionChart) {
      this.signinDistributionChart.destroy();
    }
    if (this.weeklyTrendChart) {
      this.weeklyTrendChart.destroy();
    }
  }
};
