import { Html5Qrcode, Html5QrcodeScannerState } from "html5-qrcode";

// QR Scanner Hook
export const QRScanner = {
  mounted() {
    console.log('QR Scanner mounted');
    this.initializeElements();
    this.checkCameraSupport().then(supported => {
      if (supported && this.el.dataset.active === "true") {
        this.initializeScanner();
      }
    });
  },

  updated() {
    const isActive = this.el.dataset.active === "true";

    if (isActive && !this.html5QrCode) {
      this.initializeScanner();
    } else if (!isActive && this.html5QrCode) {
      this.cleanupScanner();
    }
  },

  destroyed() {
    this.cleanupScanner();
  },
  
  // Helper methods
  initializeElements() {
    this.scannerContainer = this.el;
    this.overlay = this.el.querySelector('#qr-scanner-overlay');
    this.scanResult = null;
    this.lastScannedText = null;
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
      this.overlay.classList.remove('hidden');
    }
  },
  
  hideScannerUI() {
    if (this.overlay) {
      this.overlay.classList.add('hidden');
    }
  },
  
  async initializeScanner() {
    // Don't initialize if already active
    if (this.html5QrCode) {
      return;
    }

    // Ensure qr-reader element exists
    let qrReaderElement = this.el.querySelector('#qr-reader');
    if (!qrReaderElement) {
      qrReaderElement = document.createElement('div');
      qrReaderElement.id = 'qr-reader';
      qrReaderElement.className = 'w-full h-full';
      this.el.appendChild(qrReaderElement);
    }

    // Show scanner UI
    this.showScannerUI();

    // Configuration
    const config = {
      fps: 10,
      qrbox: this.getQrBoxDimensions,
      aspectRatio: 1.0,
      showZoomSliderIfSupported: false,
      showTorchButtonIfSupported: false,
      supportedScanTypes: [Html5Qrcode.ScanType.SCAN_TYPE_CAMERA]
    };

    // Camera constraints - prefer back camera, but allow fallback
    const constraints = {
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 640 },
        height: { ideal: 480 }
      },
      audio: false
    };

    try {
      // Create scanner instance
      this.html5QrCode = new Html5Qrcode("qr-reader");

      // Start scanning
      await this.html5QrCode.start(
        constraints,
        config,
        this.handleScanSuccess.bind(this),
        this.handleScanError.bind(this)
      );

      // Hide overlay on success
      this.hideScannerUI();
      this.el.dataset.active = "true";

    } catch (error) {
      this.handleInitializationError(error);
    }
  },
  
  getQrBoxDimensions(viewfinderWidth, viewfinderHeight) {
    const minEdgePercentage = 0.7; // 70% of the smaller dimension
    const minEdgeSize = Math.min(viewfinderWidth, viewfinderHeight);
    const qrboxSize = Math.floor(minEdgeSize * minEdgePercentage);
    
    return {
      width: qrboxSize,
      height: qrboxSize
    };
  },
  
  async handleScanSuccess(decodedText, decodedResult) {
    // Debounce multiple scans of the same code
    if (this.lastScannedText === decodedText) {
      return;
    }
    
    this.lastScannedText = decodedText;
    
    try {
      // Stop the scanner
      await this.cleanupScanner();
      
      // Notify the server about the scanned code
      this.pushEvent("process_qr", { data: decodedText });
      
      // Reset the lastScannedText after a delay to allow rescanning the same code
      setTimeout(() => {
        this.lastScannedText = null;
      }, 3000);
      
    } catch (error) {
      console.error("Error handling scan success:", error);
      this.showError("Failed to process QR code");
    }
  },
  
  handleScanError(errorMessage) {
    // Ignore errors about not finding a QR code
    if (errorMessage && !errorMessage.includes('No QR code found')) {
      console.error("QR Code scan error:", errorMessage);
      this.showError(errorMessage);
    }
  },
  
  handleInitializationError(error) {
    console.error('Scanner initialization error:', error);

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
    }

    this.showError(message);
    this.cleanupScanner();
  },
  
  async cleanupScanner() {
    if (!this.html5QrCode) return Promise.resolve();
    
    try {
      // Check if scanner is already stopped
      if (this.html5QrCode.getState() !== Html5QrcodeScannerState.NOT_STARTED) {
        await this.html5QrCode.stop();
      }
      
      // Clear the scanner UI
      this.html5QrCode.clear();
      
      return Promise.resolve();
      
    } catch (error) {
      console.error("Error cleaning up scanner:", error);
      this.showError("Error stopping the camera");
      return Promise.reject(error);
      
    } finally {
      // Always clean up references
      this.html5QrCode = null;
      this.el.dataset.active = "false";
    }
  }
};

// Register the hook
if (window.liveSocket) {
  window.liveSocket.hooks = window.liveSocket.hooks || {};
  window.liveSocket.hooks.QRScanner = QRScanner;
}

// For direct usage in LiveView hooks
export function initializeQRScanner(pushEvent) {
  const qrBoxFunction = function(viewfinderWidth, viewfinderHeight) {
    const minEdgePercentage = 0.7; // 70 percent
    const minEdgeSize = Math.min(viewfinderWidth, viewfinderHeight);
    const qrboxSize = Math.floor(minEdgeSize * minEdgePercentage);
    return {
      width: qrboxSize,
      height: qrboxSize
    };
  };

  const html5QrCode = new Html5Qrcode("qr-reader");
  const config = { 
    fps: 10,
    qrbox: qrBoxFunction,
    aspectRatio: 1.0,
    showZoomSliderIfSupported: true
  };

  // Start scanning
  html5QrCode.start(
    { facingMode: "environment" },
    config,
    (decodedText, decodedResult) => {
      // Stop scanning after successful scan
      html5QrCode.stop().then(() => {
        pushEvent("process_qr", { data: decodedText });
      }).catch(err => {
        console.error("Error stopping scanner:", err);
        pushEvent("scan_error", { error: "Failed to stop scanner" });
      });
    },
    (errorMessage) => {
      // Ignore errors about not finding a QR code
      if (errorMessage !== "No MultiFormat Readers were able to detect the code.") {
        console.error("QR Code scan error:", errorMessage);
        pushEvent("scan_error", { error: errorMessage });
      }
    }
  ).catch((err) => {
    console.error("Error starting scanner:", err);
    pushEvent("scan_error", { error: err.message || "Failed to access camera" });
  });

  // Return cleanup function
  return () => {
    if (html5QrCode && html5QrCode.isScanning) {
      html5QrCode.stop().catch(console.error);
    }
  };
}
