import React from 'react';
import { X, Zap, ZapOff, SwitchCamera, Layers } from 'lucide-react';
import { useScanner } from '../../lib/scanner/ScannerContext';

interface ScannerTopBarProps {
  onClose: () => void;
  onOpenPageManager?: () => void;
}

export const ScannerTopBar: React.FC<ScannerTopBarProps> = ({ onClose, onOpenPageManager }) => {
  const { capabilities, toggleTorch, switchCamera, session } = useScanner();

  return (
    <div className="w-full flex items-center justify-between px-4 py-3 bg-gradient-to-b from-slate-950/90 via-slate-950/60 to-transparent z-20 text-white select-none">
      {/* Close Button */}
      <button
        type="button"
        onClick={onClose}
        className="w-10 h-10 rounded-full bg-slate-900/70 backdrop-blur-md border border-white/10 flex items-center justify-center text-slate-200 hover:text-white hover:bg-slate-800 active:scale-95 transition"
        aria-label="Close scanner"
      >
        <X className="w-5 h-5" />
      </button>

      {/* Page count pill */}
      {session.pages.length > 0 && onOpenPageManager && (
        <button
          type="button"
          onClick={onOpenPageManager}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-900/80 backdrop-blur-md border border-indigo-500/40 text-xs font-semibold text-indigo-200 hover:bg-slate-800 active:scale-95 transition"
        >
          <Layers className="w-3.5 h-3.5 text-indigo-400" />
          <span>
            {session.pages.length} {session.pages.length === 1 ? 'page' : 'pages'}
          </span>
        </button>
      )}

      {/* Quick Actions (Flash & Camera switch) */}
      <div className="flex items-center gap-2">
        {capabilities.hasTorch && (
          <button
            type="button"
            onClick={toggleTorch}
            className={`w-10 h-10 rounded-full backdrop-blur-md border flex items-center justify-center transition active:scale-95 ${
              capabilities.isTorchOn
                ? 'bg-amber-400 text-slate-950 border-amber-300 shadow-lg shadow-amber-400/40 font-bold'
                : 'bg-slate-900/70 border-white/10 text-slate-200 hover:text-white hover:bg-slate-800'
            }`}
            aria-label={capabilities.isTorchOn ? 'Turn flash off' : 'Turn flash on'}
          >
            {capabilities.isTorchOn ? (
              <Zap className="w-5 h-5 fill-current" />
            ) : (
              <ZapOff className="w-5 h-5 text-slate-300" />
            )}
          </button>
        )}

        {capabilities.hasMultipleCameras && (
          <button
            type="button"
            onClick={switchCamera}
            className="w-10 h-10 rounded-full bg-slate-900/70 backdrop-blur-md border border-white/10 flex items-center justify-center text-slate-200 hover:text-white hover:bg-slate-800 active:scale-95 transition"
            aria-label="Switch camera"
          >
            <SwitchCamera className="w-5 h-5" />
          </button>
        )}
      </div>
    </div>
  );
};
