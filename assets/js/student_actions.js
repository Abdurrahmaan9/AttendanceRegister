// Handle dropdown toggle for student actions
document.addEventListener('DOMContentLoaded', function() {
  document.addEventListener('click', function(event) {
    // Check if the click is on a dropdown toggle button
    if (event.target.closest('[phx-click="toggle_dropdown"]')) {
      event.preventDefault();
      const button = event.target.closest('button');
      const dropdownId = `dropdown-${button.getAttribute('phx-value-student_id')}`;
      const dropdown = document.getElementById(dropdownId);
      
      // Close all other dropdowns
      document.querySelectorAll('[id^="dropdown-"]').forEach(function(dropdown) {
        if (dropdown.id !== dropdownId) {
          dropdown.classList.add('hidden');
        }
      });
      
      // Toggle the clicked dropdown
      if (dropdown) {
        dropdown.classList.toggle('hidden');
      }
    } else {
      // Close dropdowns when clicking outside
      document.querySelectorAll('[id^="dropdown-"]').forEach(function(dropdown) {
        dropdown.classList.add('hidden');
      });
    }
  });
  
  // Close dropdowns when clicking on a menu item
  document.addEventListener('click', function(event) {
    if (event.target.closest('[role="menuitem"]')) {
      const dropdown = event.target.closest('[role="menu"]');
      if (dropdown) {
        dropdown.classList.add('hidden');
      }
    }
  });
});
