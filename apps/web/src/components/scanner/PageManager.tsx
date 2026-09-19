import React from 'react';
import { useScanner } from '../../lib/scanner/ScannerContext';
import {
  ChevronUp,
  ChevronDown,
  Trash2,
  Plus,
  Check,
  ArrowLeft,
} from 'lucide-react';

interface PageManagerProps {
  onBack: () => void;
  onAddAnotherPage: () => void;
  onSelectPageToEdit: (index: number) => void;
  onFinishScan: () => void;
}

export const PageManager: React.FC<PageManagerProps> = ({
  onBack,
  onAddAnotherPage,
  onSelectPageToEdit,
  onFinishScan,
}) => {
  const { session, deletePage, movePage } = useScanner();
  const { pages } = session;

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-slate-950 text-white select-none overflow-hidden">
      {/* Top Header */}
      <div className="w-full flex items-center justify-between px-4 py-3 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 z-20">
        <button
          type="button"
          onClick={onBack}
          className="flex items-center gap-1.5 text-sm font-medium text-slate-300 hover:text-white active:scale-95 transition"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>

        <span className="text-sm font-semibold tracking-tight text-slate-200">
          Document Pages ({pages.length})
        </span>

        <div className="w-12" />
      </div>

      {/* Pages Grid */}
      <div className="flex-1 w-full p-4 overflow-y-auto">
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pb-6">
          {pages.map((page, index) => {
            const isFirst = index === 0;
            const isLast = index === pages.length - 1;

            return (
              <div
                key={page.id}
                className="relative flex flex-col bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-lg group hover:border-slate-700 transition"
              >
                {/* Page Number Badge */}
                <div className="absolute top-2 left-2 z-10 px-2 py-0.5 rounded-md bg-slate-950/80 backdrop-blur-md text-[11px] font-bold text-slate-200 border border-white/10">
                  Page {index + 1}
                </div>

                {/* Delete Button */}
                <button
                  type="button"
                  onClick={() => deletePage(index)}
                  className="absolute top-2 right-2 z-10 p-1.5 rounded-md bg-rose-500/20 text-rose-300 hover:bg-rose-500 hover:text-white active:scale-95 transition border border-rose-500/30"
                  aria-label={`Delete page ${index + 1}`}
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>

                {/* Thumbnail Preview Area */}
                <div
                  onClick={() => onSelectPageToEdit(index)}
                  className="w-full aspect-[3/4] bg-slate-950 flex items-center justify-center p-2 cursor-pointer"
                >
                  <img
                    src={page.thumbnailUrl || page.processedUrl}
                    alt={`Page ${index + 1}`}
                    className="max-h-full max-w-full object-contain rounded-lg shadow-sm group-hover:scale-[1.02] transition"
                  />
                </div>

                {/* Page Reorder & Navigation Controls */}
                <div className="w-full flex items-center justify-between p-2 bg-slate-900/90 border-t border-slate-800/80">
                  <div className="flex items-center gap-1">
                    <button
                      type="button"
                      disabled={isFirst}
                      onClick={() => movePage(index, index - 1)}
                      className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 disabled:opacity-30 disabled:cursor-not-allowed transition"
                      aria-label="Move page up"
                    >
                      <ChevronUp className="w-4 h-4" />
                    </button>
                    <button
                      type="button"
                      disabled={isLast}
                      onClick={() => movePage(index, index + 1)}
                      className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 disabled:opacity-30 disabled:cursor-not-allowed transition"
                      aria-label="Move page down"
                    >
                      <ChevronDown className="w-4 h-4" />
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={() => onSelectPageToEdit(index)}
                    className="text-[11px] font-semibold text-indigo-400 hover:text-indigo-300 py-1 px-2 rounded-md hover:bg-indigo-500/10 transition"
                  >
                    Edit / View
                  </button>
                </div>
              </div>
            );
          })}

          {/* Add Page Card */}
          <button
            type="button"
            onClick={onAddAnotherPage}
            className="flex flex-col items-center justify-center aspect-[3/4] rounded-2xl border-2 border-dashed border-slate-700 hover:border-indigo-500 bg-slate-900/40 hover:bg-slate-900 text-slate-400 hover:text-indigo-300 active:scale-95 transition p-4 gap-2"
          >
            <div className="w-12 h-12 rounded-full bg-slate-800 flex items-center justify-center text-indigo-400 shadow-md">
              <Plus className="w-6 h-6" />
            </div>
            <span className="text-xs font-semibold">Add Next Page</span>
          </button>
        </div>
      </div>

      {/* Bottom Action Footer */}
      <div className="w-full px-6 py-4 bg-slate-900/90 backdrop-blur-md border-t border-slate-800 flex items-center justify-between z-20">
        <button
          type="button"
          onClick={onAddAnotherPage}
          className="py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-sm flex items-center gap-2 border border-slate-700 active:scale-95 transition"
        >
          <Plus className="w-4 h-4 text-indigo-400" />
          <span>Add Page</span>
        </button>

        <button
          type="button"
          onClick={onFinishScan}
          disabled={pages.length === 0}
          className="py-3 px-6 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-sm flex items-center gap-2 shadow-lg shadow-indigo-600/30 active:scale-95 transition disabled:opacity-50"
        >
          <Check className="w-4 h-4" />
          <span>Finish & Save ({pages.length})</span>
        </button>
      </div>
    </div>
  );
};
