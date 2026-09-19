import React, { useRef } from 'react';
import { Image as ImageIcon, Check } from 'lucide-react';
import { useScanner } from '../../lib/scanner/ScannerContext';

interface ScannerControlsProps {
  onOpenPageManager: () => void;
  onFinishScan: () => void;
}

export const ScannerControls: React.FC<ScannerControlsProps> = ({
  onOpenPageManager,
  onFinishScan,
}) => {
  const { captureFrame, importImageFile, isProcessing, session, cameraStatus } = useScanner();
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const handleFileSelected = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      importImageFile(e.target.files[0]);
    }
  };

  const isCameraReady = cameraStatus === 'camera-ready';
  const pageCount = session.pages.length;
  const lastPage = pageCount > 0 ? session.pages[pageCount - 1] : null;

  return (
    <div className="w-full pb-8 pt-4 px-6 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent flex items-center justify-between z-20 select-none">
      {/* Gallery Import Input & Button */}
      <div className="w-16 flex items-center justify-center">
        <input
          type="file"
          ref={fileInputRef}
          accept="image/jpeg,image/png,image/webp,image/heic"
          className="hidden"
          onChange={handleFileSelected}
        />
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={isProcessing}
          className="w-12 h-12 rounded-2xl bg-slate-900/80 backdrop-blur-md border border-white/10 flex flex-col items-center justify-center text-slate-300 hover:text-white hover:bg-slate-800 active:scale-95 transition disabled:opacity-50"
          aria-label="Import photo from gallery"
        >
          <ImageIcon className="w-5 h-5" />
          <span className="text-[9px] font-medium mt-0.5 text-slate-400">Import</span>
        </button>
      </div>

      {/* Shutter Capture Button (72px) */}
      <div className="flex flex-col items-center">
        <button
          type="button"
          onClick={captureFrame}
          disabled={!isCameraReady || isProcessing}
          className="relative w-20 h-20 rounded-full flex items-center justify-center focus:outline-none group active:scale-95 transition disabled:opacity-40 disabled:cursor-not-allowed"
          aria-label="Capture document frame"
        >
          {/* Outer ring */}
          <div className="absolute inset-0 rounded-full border-4 border-white/80 group-hover:border-white transition-all shadow-lg shadow-black/40" />
          {/* Inner capture disc */}
          <div className="w-16 h-16 rounded-full bg-white group-hover:bg-slate-100 group-active:scale-90 transition-all flex items-center justify-center shadow-inner">
            {isProcessing && (
              <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin" />
            )}
          </div>
        </button>
      </div>

      {/* Right Action: Multi-page badge or Finish button */}
      <div className="w-16 flex items-center justify-center">
        {pageCount > 0 ? (
          <div className="relative flex flex-col items-center">
            <button
              type="button"
              onClick={onOpenPageManager}
              className="relative w-12 h-12 rounded-xl overflow-hidden border-2 border-indigo-500 shadow-md shadow-indigo-500/20 active:scale-95 transition"
              aria-label={`View ${pageCount} scanned pages`}
            >
              {lastPage && lastPage.thumbnailUrl ? (
                <img
                  src={lastPage.thumbnailUrl}
                  alt="Last scan thumbnail"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full bg-indigo-600 flex items-center justify-center text-white text-xs font-bold">
                  {pageCount}
                </div>
              )}
              {/* Badge counter */}
              <span className="absolute -top-1 -right-1 bg-indigo-600 text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center border border-white">
                {pageCount}
              </span>
            </button>
            <button
              type="button"
              onClick={onFinishScan}
              className="mt-1 text-[10px] font-bold text-indigo-400 hover:text-indigo-300 flex items-center gap-0.5"
            >
              <Check className="w-3 h-3" />
              Done
            </button>
          </div>
        ) : (
          <div className="w-12 h-12" />
        )}
      </div>
    </div>
  );
};
