const DropdownPortal = {
  mounted() {
    const button = this.el.querySelector("[data-dropdown-toggle]");
    if (!button) return;

    const dropdownId = button.getAttribute("data-dropdown-toggle");
    const dropdown = document.getElementById(dropdownId);
    if (!dropdown) return;

    this.button = button;
    this.dropdown = dropdown;
    this.isOpen = false;

    document.body.appendChild(dropdown);
    dropdown.classList.add("hidden");

    this.toggleDropdown = (e) => {
      e.stopPropagation();
      this.isOpen ? this.closeDropdown() : this.openDropdown();
    };

    this.closeDropdown = () => {
      if (!this.dropdown) return;
      this.dropdown.classList.add("hidden");
      this.isOpen = false;
    };

    this.openDropdown = () => {
      if (!this.dropdown || !this.button) return;
      
      const rect = this.button.getBoundingClientRect();
      this.dropdown.style.position = "fixed";
      this.dropdown.style.top = `${rect.bottom + window.scrollY}px`;
      this.dropdown.style.left = `${rect.left + window.scrollX}px`;
      this.dropdown.style.zIndex = "9999";
      
      this.dropdown.classList.remove("hidden");
      this.isOpen = true;
    };

    this.handleClickOutside = (e) => {
      if (
        this.dropdown &&
        this.button &&
        !this.dropdown.contains(e.target) &&
        !this.button.contains(e.target)
      ) {
        this.closeDropdown();
      }
    };

    this.handleDropdownItemClick = (e) => {
      const link = e.target.closest("a");
      if (link) {
        this.closeDropdown();
      }
    };

    this.handleEscape = (e) => {
      if (e.key === "Escape") {
        this.closeDropdown();
      }
    };

    this.handleScroll = () => {
      if (this.isOpen && this.dropdown && this.button) {
        const rect = this.button.getBoundingClientRect();
        this.dropdown.style.top = `${rect.bottom + window.scrollY}px`;
        this.dropdown.style.left = `${rect.left + window.scrollX}px`;
      }
    };

    this.button.addEventListener("click", this.toggleDropdown);
    this.dropdown.addEventListener("click", this.handleDropdownItemClick);
    document.addEventListener("click", this.handleClickOutside);
    document.addEventListener("keydown", this.handleEscape);
    window.addEventListener("scroll", this.handleScroll, true);
  },

  destroyed() {
    if (this.button) {
      this.button.removeEventListener("click", this.toggleDropdown);
    }

    if (this.dropdown) {
      this.dropdown.removeEventListener("click", this.handleDropdownItemClick);
      
      if (document.body.contains(this.dropdown)) {
        document.body.removeChild(this.dropdown);
      }
    }

    document.removeEventListener("click", this.handleClickOutside);
    document.removeEventListener("keydown", this.handleEscape);
    window.removeEventListener("scroll", this.handleScroll, true);

    this.button = null;
    this.dropdown = null;
    this.toggleDropdown = null;
    this.closeDropdown = null;
    this.openDropdown = null;
    this.handleClickOutside = null;
    this.handleDropdownItemClick = null;
    this.handleEscape = null;
    this.handleScroll = null;
  },
};

export default DropdownPortal;
