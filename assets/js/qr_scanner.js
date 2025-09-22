import { Html5Qrcode, Html5QrcodeScannerState } from "html5-qrcode";

// QR Scanner Hook
export const QRScanner = {
  mounted() {
    this.initializeElements();
    this.checkCameraSupport();
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
  
  checkCameraSupport() {
    console.log('Checking camera support...');
    const capabilities = this.logBrowserCapabilities();
    
    // Show debug info in the UI
    const debugInfo = document.createElement('div');
    debugInfo.id = 'camera-debug-info';
    debugInfo.style.padding = '10px';
    debugInfo.style.backgroundColor = '#f8f9fa';
    debugInfo.style.border = '1px solid #dee2e6';
    debugInfo.style.borderRadius = '4px';
    debugInfo.style.marginTop = '10px';
    debugInfo.style.fontFamily = 'monospace';
    debugInfo.style.fontSize = '12px';
    debugInfo.style.whiteSpace = 'pre';
    debugInfo.style.overflowX = 'auto';
    debugInfo.textContent = JSON.stringify(capabilities, null, 2);
    
    // Add debug info after the scanner container if it doesn't exist
    if (!document.getElementById('camera-debug-info')) {
      this.el.parentNode.insertBefore(debugInfo, this.el.nextSibling);
    }
    
    // First, check if we're running in a secure context (required for camera access)
    if (!capabilities.secureContext) {
      const errorMsg = 'Page not loaded in a secure context. HTTPS or localhost required.';
      console.error(errorMsg);
      this.showError('Camera access requires a secure connection (HTTPS or localhost)');
      return false;
    }
    
    // Check for basic mediaDevices support
    if (!capabilities.mediaDevices) {
      const errorMsg = 'navigator.mediaDevices not available';
      console.error(errorMsg);
      this.showError('Your browser does not support camera access. Try Chrome or Firefox on a mobile device.');
      return false;
    }
    
    // Check for getUserMedia support
    if (!capabilities.getUserMedia) {
      const errorMsg = 'navigator.mediaDevices.getUserMedia not available';
      console.error(errorMsg);
      this.showError('Your browser does not support camera access. Try Chrome or Firefox on a mobile device.');
      return false;
    }
    
    console.log('Camera support check passed');
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
    if (this.html5QrCode) return;
    
    console.log('Initializing QR scanner...');
    
    // Show scanner UI
    this.showScannerUI();
    
    // Configuration
    const config = { 
      fps: 10,
      qrbox: this.getQrBoxDimensions,
      aspectRatio: 1.0,
      showZoomSliderIfSupported: true,
      showTorchButtonIfSupported: true,
      supportedScanTypes: [Html5Qrcode.ScanType.SCAN_TYPE_CAMERA],
      // Disable experimental features that might cause issues
      experimentalFeatures: {
        useBarCodeDetectorIfSupported: false
      },
      // Try to use the native BarcodeDetector API if available
      useBarCodeDetectorIfSupported: false,
      // Disable flash by default
      showTorchButtonIfSupported: false
    };
    
    // First, check if we can enumerate devices to see available cameras
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      console.log('Available devices:', devices);
      const videoDevices = devices.filter(device => device.kind === 'videoinput');
      console.log('Video devices:', videoDevices);
      
      if (videoDevices.length === 0) {
        throw new Error('No video input devices found');
      }
    } catch (deviceError) {
      console.error('Error enumerating devices:', deviceError);
      this.showError('Could not access camera. Please check permissions.');
      return;
    }
    
    // Camera constraints - try environment (back) camera first, then user (front) camera
    const constraints = { 
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1280 },
        height: { ideal: 720 }
      },
      audio: false
    };
    
    console.log('Camera constraints:', JSON.stringify(constraints));
    
    try {
      // Create new scanner instance
      this.html5QrCode = new Html5Qrcode("qr-reader");
      
      // Start scanning
      await this.html5QrCode.start(
        constraints,
        config,
        this.handleScanSuccess.bind(this),
        this.handleScanError.bind(this)
      );
      
      // Hide the overlay after successful initialization
      this.hideScannerUI();
      
      // Mark as active
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
    
    let errorMessage = 'Failed to initialize scanner';
    let errorDetails = '';
    
    // Standard error types
    if (error.name === 'NotAllowedError') {
      errorMessage = 'Camera access was denied';
      errorDetails = 'Please check your browser settings and allow camera access to scan QR codes.';
    } else if (error.name === 'NotFoundError') {
      errorMessage = 'No camera found';
      errorDetails = 'This device does not have a camera or it cannot be accessed.';
    } else if (error.name === 'NotReadableError') {
      errorMessage = 'Camera in use';
      errorDetails = 'The camera is already in use by another application.';
    } else if (error.name === 'OverconstrainedError') {
      errorMessage = 'Camera configuration error';
      errorDetails = 'The requested camera configuration is not supported.';
    } else if (error.name === 'SecurityError') {
      errorMessage = 'Security restriction';
      errorDetails = 'Camera access is not allowed in this context. Try accessing the site over HTTPS.';
    } else if (error.message && error.message.includes('request a video mode')) {
      errorMessage = 'Unsupported video mode';
      errorDetails = 'The requested camera resolution is not supported.';
    } else if (error.message) {
      errorDetails = error.message;
    }
    
    // Log detailed error information
    console.error('Error details:', {
      name: error.name,
      message: error.message,
      constraint: error.constraint,
      stack: error.stack
    });
    
    // Show the error to the user
    this.showError(`${errorMessage}. ${errorDetails}`);
    this.cleanupScanner();
    
    // If it's a permission issue, guide the user
    if (error.name === 'NotAllowedError') {
      console.log('User needs to grant camera permissions');
      // You could add a button here to guide the user to settings
    }
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
