// Handle modal open/close
document.addEventListener('DOMContentLoaded', function() {
  // Handle close_modal event from LiveView
  window.addEventListener('phx:close_modal', (e) => {
    const modal = document.getElementById(e.detail.id);
    if (modal) {
      modal.style.display = 'none';
    }
  });

  // Close modal when clicking outside the modal content
  document.addEventListener('click', function(event) {
    const modals = document.querySelectorAll('[role="dialog"]');
    modals.forEach(modal => {
      if (event.target === modal) {
        // Find and click the close button inside this modal
        const closeButton = modal.querySelector('button[phx-click="cancel_edit"]');
        if (closeButton) {
          closeButton.click();
        }
      }
    });
  });
});
