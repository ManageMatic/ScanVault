import type { CameraCapabilities, CameraStatus } from './scannerTypes';

export interface CameraStreamResult {
  stream: MediaStream;
  capabilities: CameraCapabilities;
}

export class CameraService {
  private currentStream: MediaStream | null = null;
  private currentFacingMode: 'environment' | 'user' = 'environment';
  private torchState = false;

  /**
   * Checks if browser supports camera media devices
   */
  isSupported(): boolean {
    return !!(
      typeof navigator !== 'undefined' &&
      navigator.mediaDevices &&
      typeof navigator.mediaDevices.getUserMedia === 'function'
    );
  }

  /**
   * Starts or restarts the camera stream
   */
  async startStream(
    preferredFacingMode: 'environment' | 'user' = 'environment'
  ): Promise<CameraStreamResult> {
    if (!this.isSupported()) {
      throw new Error('UNSUPPORTED_BROWSER');
    }

    // Stop existing stream if running
    this.stopStream();

    this.currentFacingMode = preferredFacingMode;

    const constraints: MediaStreamConstraints = {
      audio: false,
      video: {
        facingMode: { ideal: preferredFacingMode },
        width: { ideal: 1920, min: 640 },
        height: { ideal: 1080, min: 480 },
      },
    };

    try {
      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      this.currentStream = stream;

      const capabilities = await this.inspectCapabilities(stream);
      return { stream, capabilities };
    } catch (err: unknown) {
      const error = err as Error;
      if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
        throw new Error('PERMISSION_DENIED');
      }
      if (error.name === 'NotFoundError' || error.name === 'DevicesNotFoundError') {
        throw new Error('CAMERA_UNAVAILABLE');
      }
      if (error.name === 'NotReadableError' || error.name === 'TrackStartError') {
        throw new Error('CAMERA_BUSY');
      }
      if (error.name === 'OverconstrainedError') {
        // Fallback to basic video constraint if overconstrained
        const fallbackStream = await navigator.mediaDevices.getUserMedia({
          audio: false,
          video: true,
        });
        this.currentStream = fallbackStream;
        const capabilities = await this.inspectCapabilities(fallbackStream);
        return { stream: fallbackStream, capabilities };
      }
      throw error;
    }
  }

  /**
   * Stops all active tracks on the current camera stream
   */
  stopStream(streamToStop?: MediaStream | null): void {
    const stream = streamToStop || this.currentStream;
    if (stream) {
      stream.getTracks().forEach((track) => {
        try {
          track.stop();
        } catch {
          // Ignore track stop error
        }
      });
    }
    if (!streamToStop || streamToStop === this.currentStream) {
      this.currentStream = null;
      this.torchState = false;
    }
  }

  /**
   * Switches facing mode between back (environment) and front (user)
   */
  async switchCamera(
    currentFacingMode: 'environment' | 'user'
  ): Promise<CameraStreamResult> {
    const nextFacing = currentFacingMode === 'environment' ? 'user' : 'environment';
    return this.startStream(nextFacing);
  }

  /**
   * Toggles the LED torch/flashlight if supported by the device
   */
  async toggleTorch(stream: MediaStream, enable?: boolean): Promise<boolean> {
    const videoTrack = stream.getVideoTracks()[0];
    if (!videoTrack) return false;

    try {
      const targetState = enable !== undefined ? enable : !this.torchState;
      await (videoTrack as any).applyConstraints({
        advanced: [{ torch: targetState }],
      });
      this.torchState = targetState;
      return this.torchState;
    } catch {
      return false;
    }
  }

  /**
   * Inspects track capabilities and available devices
   */
  async inspectCapabilities(stream: MediaStream): Promise<CameraCapabilities> {
    let hasTorch = false;
    let hasZoom = false;
    let minZoom = 1;
    let maxZoom = 1;
    let currentZoom = 1;

    const videoTrack = stream.getVideoTracks()[0];
    if (videoTrack) {
      try {
        const trackWithCaps = videoTrack as MediaStreamTrack & {
          getCapabilities?: () => Record<string, unknown>;
          getSettings?: () => Record<string, unknown>;
        };

        if (typeof trackWithCaps.getCapabilities === 'function') {
          const caps = trackWithCaps.getCapabilities();
          if ('torch' in caps) {
            hasTorch = true;
          }
          if ('zoom' in caps && typeof caps.zoom === 'object' && caps.zoom !== null) {
            hasZoom = true;
            const zoomObj = caps.zoom as { min?: number; max?: number };
            minZoom = zoomObj.min || 1;
            maxZoom = zoomObj.max || 1;
          }
        }

        if (typeof trackWithCaps.getSettings === 'function') {
          const settings = trackWithCaps.getSettings();
          if (typeof settings.zoom === 'number') {
            currentZoom = settings.zoom;
          }
        }
      } catch {
        // Ignore capability detection error
      }
    }

    let hasMultipleCameras = false;
    try {
      if (typeof navigator !== 'undefined' && navigator.mediaDevices?.enumerateDevices) {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter((d) => d.kind === 'videoinput');
        hasMultipleCameras = videoDevices.length > 1;
      }
    } catch {
      // Ignore
    }

    return {
      hasTorch,
      isTorchOn: this.torchState,
      hasZoom,
      minZoom,
      maxZoom,
      currentZoom,
      hasMultipleCameras,
      facingMode: this.currentFacingMode,
    };
  }

  /**
   * Captures a high-resolution frame from the video element to a JPEG Blob
   */
  async captureFrame(videoElement: HTMLVideoElement, quality = 0.95): Promise<{
    blob: Blob;
    width: number;
    height: number;
  }> {
    const width = videoElement.videoWidth || 1280;
    const height = videoElement.videoHeight || 720;

    if (width <= 0 || height <= 0) {
      throw new Error('Invalid video frame dimensions.');
    }

    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;

    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new Error('Could not obtain canvas 2D rendering context.');
    }

    // Mirror image if using front/user camera for natural feel
    if (this.currentFacingMode === 'user') {
      ctx.translate(width, 0);
      ctx.scale(-1, 1);
    }

    ctx.drawImage(videoElement, 0, 0, width, height);

    return new Promise((resolve, reject) => {
      canvas.toBlob(
        (blob) => {
          if (!blob || blob.size === 0) {
            reject(new Error('Failed to create captured image Blob.'));
            return;
          }
          resolve({ blob, width, height });
        },
        'image/jpeg',
        quality
      );
    });
  }
}

export const cameraService = new CameraService();

/**
 * Functional wrappers for easy consumption in React hooks
 */
export async function startCameraStream(
  preferredFacingMode: 'environment' | 'user' = 'environment'
): Promise<{
  success: boolean;
  stream?: MediaStream;
  capabilities: CameraCapabilities;
  status: CameraStatus;
  error?: string;
}> {
  try {
    const result = await cameraService.startStream(preferredFacingMode);
    return {
      success: true,
      stream: result.stream,
      capabilities: result.capabilities,
      status: 'camera-ready',
    };
  } catch (err: unknown) {
    const msg = (err as Error).message;
    let status: CameraStatus = 'error';
    let error = 'Unable to access camera';

    if (msg === 'PERMISSION_DENIED') {
      status = 'permission-denied';
      error = 'Camera permission was denied. Please allow camera access in browser settings.';
    } else if (msg === 'CAMERA_UNAVAILABLE') {
      status = 'camera-unavailable';
      error = 'No camera device found on this system.';
    } else if (msg === 'CAMERA_BUSY') {
      status = 'camera-busy';
      error = 'Camera is currently in use by another application.';
    } else if (msg === 'UNSUPPORTED_BROWSER') {
      status = 'unsupported-browser';
      error = 'Your browser does not support camera capture APIs.';
    }

    return {
      success: false,
      capabilities: {
        hasTorch: false,
        isTorchOn: false,
        hasZoom: false,
        minZoom: 1,
        maxZoom: 1,
        currentZoom: 1,
        hasMultipleCameras: false,
        facingMode: preferredFacingMode,
      },
      status,
      error,
    };
  }
}

export function stopMediaStream(stream?: MediaStream | null): void {
  cameraService.stopStream(stream);
}

export async function switchCameraDevice(
  _currentStream: MediaStream,
  targetFacingMode: 'environment' | 'user'
) {
  return startCameraStream(targetFacingMode);
}

export async function toggleCameraTorch(
  stream: MediaStream,
  targetState?: boolean
): Promise<boolean> {
  return cameraService.toggleTorch(stream, targetState);
}

export async function captureFrameAsBlob(
  videoElement: HTMLVideoElement,
  quality = 0.95
): Promise<Blob> {
  const res = await cameraService.captureFrame(videoElement, quality);
  return res.blob;
}
