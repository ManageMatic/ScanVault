import React from 'react';
import { useScanner } from '../../lib/scanner/ScannerContext';
import { RotateCw, Plus, Check, Trash2, ArrowLeft, Loader2, Layers } from 'lucide-react';

interface PageEditorProps {
  onAddAnotherPage: () => void;
  onOpenPageManager: () => void;
  onFinishScan: () => void;
  onRetake: () => void;
}

export const PageEditor: React.FC<PageEditorProps> = ({
  onAddAnotherPage,
  onOpenPageManager,
  onFinishScan,
  onRetake,
}) => {
  const { session, rotateCurrentPage, deletePage, isProcessing } = useScanner();

  const activeIndex = session.activePageIndex;
  const activePage = session.pages[activeIndex];
  const pageCount = session.pages.length;

  if (!activePage) {
    return null;
  }

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-slate-950 text-white select-none overflow-hidden">
      {/* Top Header */}
      <div className="w-full flex items-center justify-between px-4 py-3 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 z-20">
        <button
          type="button"
          onClick={onRetake}
          className="flex items-center gap-1.5 text-sm font-medium text-slate-300 hover:text-white active:scale-95 transition"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Retake</span>
        </button>

        <span className="text-sm font-semibold tracking-tight text-slate-200">
          Page {activeIndex + 1} of {pageCount}
        </span>

        <button
          type="button"
          onClick={() => deletePage(activeIndex)}
          className="p-2 rounded-lg text-rose-400 hover:bg-rose-500/10 active:scale-95 transition"
          aria-label="Delete this page"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>

      {/* Warped Page Preview */}
      <div className="relative flex-1 w-full h-full p-4 flex items-center justify-center overflow-hidden">
        <div className="relative max-w-full max-h-full rounded-xl overflow-hidden shadow-2xl border border-slate-800 bg-slate-900 flex items-center justify-center">
          {isProcessing ? (
            <div className="p-12 flex flex-col items-center justify-center">
              <Loader2 className="w-8 h-8 text-indigo-400 animate-spin mb-2" />
              <p className="text-xs text-slate-400">Processing page...</p>
            </div>
          ) : (
            <img
              src={activePage.processedUrl}
              alt={`Scanned page ${activeIndex + 1}`}
              className="max-h-[65vh] max-w-full object-contain rounded-lg shadow-inner"
            />
          )}
        </div>
      </div>

      {/* Bottom Tool & Progression Bar */}
      <div className="w-full px-6 py-4 bg-slate-900/90 backdrop-blur-md border-t border-slate-800 flex flex-col gap-3 z-20">
        <div className="flex items-center justify-between">
          {/* Rotate Tool */}
          <button
            type="button"
            onClick={rotateCurrentPage}
            disabled={isProcessing}
            className="flex items-center gap-1.5 py-2.5 px-3.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700 active:scale-95 transition disabled:opacity-50"
          >
            <RotateCw className="w-4 h-4 text-cyan-400" />
            <span>Rotate 90°</span>
          </button>

          {/* Manage Pages (if > 1) */}
          {pageCount > 1 && (
            <button
              type="button"
              onClick={onOpenPageManager}
              className="flex items-center gap-1.5 py-2.5 px-3.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-indigo-300 text-xs font-semibold border border-slate-700 active:scale-95 transition"
            >
              <Layers className="w-4 h-4 text-indigo-400" />
              <span>All Pages ({pageCount})</span>
            </button>
          )}
        </div>

        {/* Primary Progression Actions */}
        <div className="grid grid-cols-2 gap-3">
          <button
            type="button"
            onClick={onAddAnotherPage}
            disabled={isProcessing}
            className="py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-sm flex items-center justify-center gap-2 border border-slate-700 active:scale-95 transition disabled:opacity-50"
          >
            <Plus className="w-4 h-4 text-indigo-400" />
            <span>Add Next Page</span>
          </button>

          <button
            type="button"
            onClick={onFinishScan}
            disabled={isProcessing}
            className="py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-sm flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/30 active:scale-95 transition disabled:opacity-50"
          >
            <Check className="w-4 h-4" />
            <span>Finish & Save</span>
          </button>
        </div>
      </div>
    </div>
  );
};
