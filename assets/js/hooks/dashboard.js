import Chart from "chart.js/auto";

let Hooks = {}

// Hook for the Lecturer Dashboard
Hooks.SystemCharts = {
  mounted() {
    const el = this.el;
    const labels = JSON.parse(el.dataset.labels);
    const memData = JSON.parse(el.dataset.memSeries);
    const runqData = JSON.parse(el.dataset.runqSeries);
    const ioInData = JSON.parse(el.dataset.ioinSeries);
    const ioOutData = JSON.parse(el.dataset.iooutSeries);

    // Memory Usage Chart
    new Chart(document.getElementById('systemMemChart'), {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{ label: 'Memory (MB)', data: memData, borderColor: '#3B82F6', fill: true }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    });

    // Add similar initializations for systemRunqChart and systemIOChart...
  }
}

// Hook for the Student Dashboard
Hooks.StudentCharts = {
  mounted() {
    const el = this.el;
    const attendanceLabels = JSON.parse(el.dataset.attendanceLabels);
    const attendanceCounts = JSON.parse(el.dataset.attendanceCounts);
    const courseLabels = JSON.parse(el.dataset.courseLabels);
    const courseCounts = JSON.parse(el.dataset.courseCounts);

    // Attendance Trend
    new Chart(document.getElementById('attendanceTrendChart'), {
      type: 'line',
      data: {
        labels: attendanceLabels,
        datasets: [{
          label: 'Attendance',
          data: attendanceCounts,
          borderColor: '#3B82F6',
          tension: 0.3
        }]
      }
    });

    // Course Distribution (Doughnut)
    new Chart(document.getElementById('courseDistChart'), {
      type: 'doughnut',
      data: {
        labels: courseLabels,
        datasets: [{
          data: courseCounts,
          backgroundColor: ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B']
        }]
      }
    });
  }
}

// Finally, pass Hooks to your LiveSocket
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })