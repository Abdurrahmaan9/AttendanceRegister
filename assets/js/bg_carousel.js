// Local background image carousel
const bgCarousel = {
  debugElement: null,
  
  mounted() {
    console.log('Local background carousel mounted');
    this.debugElement = document.getElementById('bg-debug');
    this.updateDebug('Initializing carousel...');
    
    // Base path for static assets - try both with and without leading slash
    const basePath = '/images/';
    
    // Array of local background image paths - try multiple formats
    const imageNames = [
      'Screenshot from 2024-11-05 23-34-40.png',
      'Screenshot from 2024-11-05 23-35-17.png',
      'Screenshot from 2024-11-05 23-35-44.png'
    ];
    
    // Create multiple path variations to test
    this.images = [];
    imageNames.forEach(name => {
      // Try with leading slash
      this.images.push(`/images/${name}`);
      // Try without leading slash
      this.images.push(`images/${name}`);
      // Try with full URL
      this.images.push(`${window.location.origin}/images/${name}`);
    });
    
    // Add a fallback color if no images load
    this.fallbackColor = 'linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)';
    
    this.updateDebug(`Testing ${this.images.length} image paths`);
    console.log('Testing image paths:', this.images);
    
    this.currentIndex = 0;
    this.carousel = document.getElementById('bg-carousel');
    
    if (!this.carousel) {
      console.error('Could not find bg-carousel element');
      return;
    }
    
    // Preload images
    this.preloadImages();
    
    // Set initial background
    this.updateBackground();
    
    // Change background every 5 seconds
    this.interval = setInterval(() => this.nextBackground(), 5000);
    
    // Clean up on unmount
    this.el.addEventListener('phx:before-unmount', () => {
      if (this.interval) clearInterval(this.interval);
    });
  },
  
  preloadImages() {
    this.images.forEach((src) => {
      const img = new Image();
      img.src = src;
    });
  },
  
  nextBackground() {
    this.currentIndex = (this.currentIndex + 1) % this.images.length;
    this.updateBackground();  
  },
  
  updateDebug(message) {
    if (this.debugElement) {
      this.debugElement.textContent = message;
    }
    console.log(`[BgCarousel] ${message}`);
  },
  
  updateBackground() {
    if (!this.carousel) {
      this.updateDebug('Error: Carousel element not found');
      return;
    }
    
    const img = this.images[this.currentIndex];
    this.updateDebug(`Loading: ${img}`);
    
    // Fade out
    this.carousel.style.transition = 'opacity 1s ease-in-out';
    this.carousel.style.opacity = 0.3;
    
    // Create a test image to check if it loads
    const testImg = new Image();
    
    testImg.onload = () => {
      this.updateDebug(`Success: ${img}`);
      this.applyBackground(img);
      this.currentIndex = (this.currentIndex + 1) % this.images.length;
    };
    
    testImg.onerror = () => {
      this.updateDebug(`Failed: ${img}`);
      // Try next image
      this.currentIndex = (this.currentIndex + 1) % this.images.length;
      
      // If we've tried all images, use fallback
      if (this.currentIndex === 0) {
        this.updateDebug('Using fallback background');
        this.applyBackground(this.fallbackColor, true);
      } else {
        // Try next image after a short delay
        setTimeout(() => this.updateBackground(), 1000);
      }
    };
    
    // Start loading the image
    testImg.src = img;
  },
  
  applyBackground(src, isColor = false) {
    if (!this.carousel) return;
    
    const bgValue = isColor ? src : `url('${src}')`;
    this.carousel.style.backgroundImage = bgValue;
    this.carousel.style.backgroundSize = 'cover';
    this.carousel.style.backgroundPosition = 'center';
    this.carousel.style.backgroundRepeat = 'no-repeat';
    this.carousel.style.opacity = 1;
  }
};

export default bgCarousel;
