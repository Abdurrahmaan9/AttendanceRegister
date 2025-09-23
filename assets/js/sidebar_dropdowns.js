// Handle sidebar dropdown toggles
document.addEventListener("DOMContentLoaded", () => {
  // Handle dropdown toggle
  document.addEventListener('click', (e) => {
    // Check if the clicked element is a dropdown toggle button
    const dropdownButton = e.target.closest('[data-dropdown-target]');
    if (dropdownButton) {
      e.preventDefault();
      e.stopPropagation();
      
      const dropdownId = dropdownButton.getAttribute('data-dropdown-target');
      const dropdown = document.getElementById(`${dropdownId}-dropdown`);
      
      if (dropdown) {
        const isExpanded = dropdownButton.getAttribute('aria-expanded') === 'true';
        const shouldExpand = !isExpanded;
        
        // Close all other dropdowns
        document.querySelectorAll('.dropdown-content').forEach(d => {
          if (d !== dropdown) {
            d.classList.add('hidden');
            d.classList.remove('block');
          }
        });
        
        // Toggle the clicked dropdown
        dropdownButton.setAttribute('aria-expanded', shouldExpand);
        dropdown.classList.toggle('hidden', !shouldExpand);
        dropdown.classList.toggle('block', shouldExpand);
        
        // Rotate the chevron icon
        const chevron = dropdownButton.querySelector('svg:last-child');
        if (chevron) {
          chevron.classList.toggle('rotate-90', shouldExpand);
        }
      }
    }
    
    // Close dropdown when clicking outside
    const clickedInsideDropdown = e.target.closest('.dropdown-content') || e.target.closest('[data-dropdown-target]');
    if (!clickedInsideDropdown) {
      document.querySelectorAll('.dropdown-content').forEach(dropdown => {
        dropdown.classList.add('hidden');
        dropdown.classList.remove('block');
      });
      
      document.querySelectorAll('[data-dropdown-target]').forEach(button => {
        button.setAttribute('aria-expanded', 'false');
        const chevron = button.querySelector('svg:last-child');
        if (chevron) {
          chevron.classList.remove('rotate-90');
        }
      });
    }
  });
});
