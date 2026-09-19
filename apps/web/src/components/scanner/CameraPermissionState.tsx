import React, { useRef } from 'react';
import { Camera, Image as ImageIcon, RefreshCw, AlertCircle, ShieldAlert } from 'lucide-react';
import type { CameraStatus } from '../../lib/scanner/scannerTypes';

interface CameraPermissionStateProps {
  status: CameraStatus;
  errorMessage: string | null;
  onRetry: () => void;
  onImportFile: (file: File) => void;
  onCancel: () => void;
}

export const CameraPermissionState: React.FC<CameraPermissionStateProps> = ({
  status,
  errorMessage,
  onRetry,
  onImportFile,
  onCancel,
}) => {
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const isDenied = status === 'permission-denied';
  const isBusy = status === 'camera-busy';
  const isUnsupported = status === 'unsupported-browser';

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onImportFile(e.target.files[0]);
    }
  };

  return (
    <div className="flex-1 flex flex-col items-center justify-center p-6 text-center bg-slate-950 text-white select-none">
      <div className="w-16 h-16 rounded-2xl bg-slate-800/80 border border-slate-700/80 flex items-center justify-center mb-6 text-amber-400 shadow-xl">
        {isDenied ? (
          <ShieldAlert className="w-8 h-8 text-rose-400" />
        ) : isBusy ? (
          <AlertCircle className="w-8 h-8 text-amber-400" />
        ) : (
          <Camera className="w-8 h-8 text-indigo-400" />
        )}
      </div>

      <h2 className="text-xl font-bold tracking-tight mb-2">
        {isDenied
          ? 'Camera Permission Required'
          : isBusy
          ? 'Camera is in Use'
          : isUnsupported
          ? 'Camera Unsupported'
          : 'Unable to Access Camera'}
      </h2>

      <p className="text-sm text-slate-400 max-w-sm mb-6 leading-relaxed">
        {errorMessage ||
          (isDenied
            ? 'ScanVault needs camera access to scan physical documents. Please enable camera permissions in your browser settings.'
            : 'Another application might be using your camera. Close other video apps and retry, or import an image from your device.')}
      </p>

      {/* Hidden file input for photo import */}
      <input
        type="file"
        ref={fileInputRef}
        accept="image/jpeg,image/png,image/webp,image/heic"
        className="hidden"
        onChange={handleFileChange}
      />

      <div className="flex flex-col w-full max-w-xs gap-3">
        {!isUnsupported && (
          <button
            type="button"
            onClick={onRetry}
            className="w-full py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/30 transition"
          >
            <RefreshCw className="w-4 h-4" />
            Try Camera Again
          </button>
        )}

        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          className="w-full py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 active:bg-slate-800 text-slate-200 font-semibold flex items-center justify-center gap-2 border border-slate-700 transition"
        >
          <ImageIcon className="w-4 h-4 text-slate-400" />
          Choose from Gallery / Files
        </button>

        <button
          type="button"
          onClick={onCancel}
          className="w-full py-2.5 px-4 text-sm font-medium text-slate-400 hover:text-slate-200 transition mt-1"
        >
          Cancel & Return to Vault
        </button>
      </div>

      {isDenied && (
        <div className="mt-8 p-4 rounded-xl bg-slate-900/80 border border-slate-800 text-left max-w-xs text-xs text-slate-400">
          <p className="font-semibold text-slate-300 mb-1">How to enable camera:</p>
          <ol className="list-decimal pl-4 space-y-1">
            <li>Tap the padlock or site settings icon in your browser address bar.</li>
            <li>Select <strong>Permissions</strong> or <strong>Site Settings</strong>.</li>
            <li>Set <strong>Camera</strong> to <strong>Allow</strong>.</li>
            <li>Reload or tap "Try Camera Again".</li>
          </ol>
        </div>
      )}
    </div>
  );
};
