import React, { useEffect } from 'react';
import { useScanner } from '../../lib/scanner/ScannerContext';
import { DetectionOverlay } from './DetectionOverlay';
import { ScannerTopBar } from './ScannerTopBar';
import { ScannerControls } from './ScannerControls';
import { CameraPermissionState } from './CameraPermissionState';
import { Loader2 } from 'lucide-react';

interface CameraPreviewProps {
  onClose: () => void;
  onOpenPageManager: () => void;
  onFinishScan: () => void;
}

export const CameraPreview: React.FC<CameraPreviewProps> = ({
  onClose,
  onOpenPageManager,
  onFinishScan,
}) => {
  const {
    videoRef,
    cameraStatus,
    errorMessage,
    liveCorners,
    startCamera,
    importImageFile,
  } = useScanner();

  useEffect(() => {
    startCamera();
  }, [startCamera]);

  const isErrorState =
    cameraStatus === 'permission-denied' ||
    cameraStatus === 'camera-unavailable' ||
    cameraStatus === 'camera-busy' ||
    cameraStatus === 'unsupported-browser' ||
    cameraStatus === 'error';

  if (isErrorState) {
    return (
      <CameraPermissionState
        status={cameraStatus}
        errorMessage={errorMessage}
        onRetry={startCamera}
        onImportFile={importImageFile}
        onCancel={onClose}
      />
    );
  }

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-black overflow-hidden select-none">
      {/* Top Controls Overlay */}
      <ScannerTopBar onClose={onClose} onOpenPageManager={onOpenPageManager} />

      {/* Center Video Viewport */}
      <div className="relative flex-1 w-full h-full flex items-center justify-center overflow-hidden">
        {cameraStatus === 'requesting-permission' && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-950 z-10 text-white p-6">
            <Loader2 className="w-8 h-8 text-indigo-400 animate-spin mb-3" />
            <p className="text-sm text-slate-300 font-medium">Starting camera...</p>
          </div>
        )}

        {/* Video feed */}
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted
          className="absolute inset-0 w-full h-full object-cover"
        />

        {/* Live Document Edge Detection HUD */}
        {cameraStatus === 'camera-ready' && (
          <DetectionOverlay corners={liveCorners} />
        )}

        {/* Helper text */}
        <div className="absolute top-16 left-0 right-0 flex justify-center pointer-events-none z-10">
          <div className="px-3.5 py-1.5 rounded-full bg-slate-950/60 backdrop-blur-md border border-white/10 text-xs font-medium text-slate-200 shadow-sm animate-fade-in">
            Align document within frame
          </div>
        </div>
      </div>

      {/* Bottom Shutter & Action Bar */}
      <ScannerControls
        onOpenPageManager={onOpenPageManager}
        onFinishScan={onFinishScan}
      />
    </div>
  );
};
