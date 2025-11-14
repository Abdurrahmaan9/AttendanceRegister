import { Html5Qrcode, Html5QrcodeScannerState } from "html5-qrcode";

// QR Scanner Hook
export const QRScanner = {
  mounted() {
    console.log('=== QR Scanner mounted ===');
    console.log('Initial data-active:', this.el.dataset.active);
    
    this.initializeElements();
    
    // Log browser capabilities for debugging
    this.logBrowserCapabilities();
    
    // Check camera support
    this.checkCameraSupport().then(supported => {
      console.log('Camera supported:', supported);
      console.log('Active state:', this.el.dataset.active);
      
      if (supported && this.el.dataset.active === "true") {
        console.log('Initializing scanner on mount');
        this.initializeScanner();
      } else {
        console.log('Not initializing on mount - waiting for user action');
      }
    });
  },

  updated() {
    console.log('=== QR Scanner updated ===');
    const isActive = this.el.dataset.active === "true";
    console.log('Updated - isActive:', isActive);
    console.log('Updated - html5QrCode exists:', !!this.html5QrCode);

    if (isActive && !this.html5QrCode) {
      console.log('Starting scanner from updated()');
      this.initializeScanner();
    } else if (!isActive && this.html5QrCode) {
      console.log('Stopping scanner from updated()');
      this.cleanupScanner();
    } else {
      console.log('No action needed in updated()');
    }
  },

  destroyed() {
    console.log('=== QR Scanner destroyed ===');
    this.cleanupScanner();
  },
  
  // Helper methods
  initializeElements() {
    this.scannerContainer = this.el;
    this.overlay = this.el.querySelector('#qr-scanner-overlay');
    this.scanResult = null;
    this.lastScannedText = null;
    this.isInitializing = false; // Prevent duplicate initialization
    
    console.log('Elements initialized:', {
      container: !!this.scannerContainer,
      overlay: !!this.overlay
    });
  },
  
  logBrowserCapabilities() {
    const capabilities = {
      secureContext: window.isSecureContext,
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      mediaDevices: !!navigator.mediaDevices,
      getUserMedia: !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia),
      enumerateDevices: !!(navigator.mediaDevices && navigator.mediaDevices.enumerateDevices),
      permissions: !!navigator.permissions,
      permissionsQuery: !!(navigator.permissions && navigator.permissions.query)
    };
    
    console.log('Browser capabilities:', capabilities);
    return capabilities;
  },
  
  async checkCameraSupport() {
    // Check if we're running in a secure context or localhost (for development)
    const isLocalhost = ['localhost', '127.0.0.1', '0.0.0.0'].includes(window.location.hostname);
    const isSecure = window.isSecureContext || isLocalhost;

    console.log('Security check:', { isLocalhost, isSecure, hostname: window.location.hostname });

    if (!isSecure) {
      this.showError('Camera access requires a secure connection (HTTPS or localhost)');
      return false;
    }

    // Check for basic mediaDevices support
    if (!navigator.mediaDevices) {
      this.showError('Your browser does not support camera access. Try Chrome or Firefox.');
      return false;
    }

    // Check for getUserMedia support
    if (!navigator.mediaDevices.getUserMedia) {
      this.showError('Your browser does not support camera access. Try Chrome or Firefox.');
      return false;
    }

    return true;
  },
  
  showError(message) {
    console.error('Showing error:', message);
    this.pushEvent("scan_error", { error: message });
  },
  
  disableScanner() {
    this.el.classList.add('opacity-50', 'cursor-not-allowed');
    this.el.querySelectorAll('button, [phx-click]').forEach(el => {
      el.disabled = true;
    });
  },
  
  showScannerUI() {
    if (this.overlay) {
      console.log('Showing scanner UI (removing hidden class)');
      this.overlay.classList.remove('hidden');
    }
  },
  
  hideScannerUI() {
    if (this.overlay) {
      console.log('Hiding scanner UI (adding hidden class)');
      this.overlay.classList.add('hidden');
    }
  },
  
  async initializeScanner() {
    console.log('=== initializeScanner called ===');
    
    // Prevent duplicate initialization
    if (this.html5QrCode || this.isInitializing) {
      console.log('Scanner already active or initializing, skipping');
      return;
    }

    this.isInitializing = true;

    // Ensure qr-reader element exists
    let qrReaderElement = this.el.querySelector('#qr-reader');
    if (!qrReaderElement) {
      console.log('Creating qr-reader element');
      qrReaderElement = document.createElement('div');
      qrReaderElement.id = 'qr-reader';
      qrReaderElement.className = 'w-full h-full';
      this.el.appendChild(qrReaderElement);
    } else {
      console.log('qr-reader element already exists');
    }

    // Show scanner UI
    this.showScannerUI();

    // Configuration
    const config = {
      fps: 10,
      qrbox: this.getQrBoxDimensions,
      aspectRatio: 1.0,
      showZoomSliderIfSupported: false,
      showTorchButtonIfSupported: false
    };

    try {
      console.log('Creating Html5Qrcode instance');
      this.html5QrCode = new Html5Qrcode("qr-reader");

      // Try to get cameras first to determine best approach
      const cameras = await Html5Qrcode.getCameras();
      console.log('Available cameras:', cameras);

      let cameraId;
      
      if (cameras && cameras.length > 0) {
        // Prefer back camera (environment facing)
        const backCamera = cameras.find(camera => 
          camera.label.toLowerCase().includes('back') || 
          camera.label.toLowerCase().includes('rear') ||
          camera.label.toLowerCase().includes('environment')
        );
        
        cameraId = backCamera ? backCamera.id : cameras[cameras.length - 1].id;
        console.log('Using camera:', cameraId);
      } else {
        // Fallback to constraint-based approach with correct format
        console.log('No specific cameras found, using facingMode constraint');
        cameraId = { facingMode: "environment" }; // FIXED: Simple string value
      }

      console.log('Starting scanner with camera:', cameraId);
      await this.html5QrCode.start(
        cameraId,
        config,
        this.handleScanSuccess.bind(this),
        this.handleScanError.bind(this)
      );

      console.log('Scanner started successfully!');
      
      // Hide overlay on success
      this.hideScannerUI();
      this.el.dataset.active = "true";
      this.isInitializing = false;

    } catch (error) {
      console.error('Scanner initialization failed:', error);
      this.isInitializing = false;
      this.handleInitializationError(error);
    }
  },
  
  getQrBoxDimensions(viewfinderWidth, viewfinderHeight) {
    const minEdgePercentage = 0.7; // 70% of the smaller dimension
    const minEdgeSize = Math.min(viewfinderWidth, viewfinderHeight);
    const qrboxSize = Math.floor(minEdgeSize * minEdgePercentage);
    
    console.log('QR box dimensions:', { viewfinderWidth, viewfinderHeight, qrboxSize });
    
    return {
      width: qrboxSize,
      height: qrboxSize
    };
  },
  
  async handleScanSuccess(decodedText, decodedResult) {
    console.log('=== QR Code Scanned ===', decodedText);
    
    // Debounce multiple scans of the same code
    if (this.lastScannedText === decodedText) {
      console.log('Duplicate scan ignored');
      return;
    }
    
    this.lastScannedText = decodedText;
    
    try {
      // Stop the scanner
      await this.cleanupScanner();
      
      console.log('Pushing process_qr event to server');
      // Notify the server about the scanned code
      this.pushEvent("process_qr", { data: decodedText });
      
      // Reset the lastScannedText after a delay to allow rescanning the same code
      setTimeout(() => {
        console.log('Resetting lastScannedText');
        this.lastScannedText = null;
      }, 3000);
      
    } catch (error) {
      console.error("Error handling scan success:", error);
      this.showError("Failed to process QR code");
    }
  },
  
  handleScanError(errorMessage) {
    // Ignore errors about not finding a QR code (these happen continuously while scanning)
    if (errorMessage && !errorMessage.includes('No QR code found') && !errorMessage.includes('No MultiFormat Readers')) {
      console.error("QR Code scan error:", errorMessage);
    }
  },
  
  handleInitializationError(error) {
    console.error('=== Scanner initialization error ===', error);

    let message = 'Unable to access camera';

    if (error.name === 'NotAllowedError') {
      message = 'Camera access denied. Please allow camera access in your browser settings and try again.';
    } else if (error.name === 'NotFoundError') {
      message = 'No camera found on this device.';
    } else if (error.name === 'NotReadableError') {
      message = 'Camera is already in use by another application.';
    } else if (error.name === 'OverconstrainedError') {
      message = 'Camera configuration not supported. Try using a different browser.';
    } else if (error.name === 'SecurityError') {
      message = 'Camera access blocked. Please ensure you are using HTTPS.';
    } else if (error.message) {
      message = `Camera error: ${error.message}`;
    }

    this.showError(message);
    this.cleanupScanner();
  },
  
  async cleanupScanner() {
    console.log('=== Cleanup scanner called ===');
    
    if (!this.html5QrCode) {
      console.log('No scanner to cleanup');
      return Promise.resolve();
    }
    
    try {
      const currentState = this.html5QrCode.getState();
      console.log('Current scanner state:', currentState);
      
      // Check if scanner is already stopped
      if (currentState !== Html5QrcodeScannerState.NOT_STARTED) {
        console.log('Stopping scanner...');
        await this.html5QrCode.stop();
        console.log('Scanner stopped');
      }
      
      // Clear the scanner UI
      console.log('Clearing scanner UI');
      this.html5QrCode.clear();
      
      return Promise.resolve();
      
    } catch (error) {
      console.error("Error cleaning up scanner:", error);
      this.showError("Error stopping the camera");
      return Promise.reject(error);
      
    } finally {
      // Always clean up references
      console.log('Cleaning up references');
      this.html5QrCode = null;
      this.isInitializing = false;
      this.el.dataset.active = "false";
    }
  }
};