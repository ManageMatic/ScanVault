import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useScanner } from '../../lib/scanner/ScannerContext';
import { Check, RotateCcw, Maximize2, Sparkles, ArrowLeft, Loader2 } from 'lucide-react';
import type { Point } from '../../lib/scanner/scannerTypes';

interface CornerEditorProps {
  onCancel: () => void;
}

type CornerKey = 'tl' | 'tr' | 'br' | 'bl';

export const CornerEditor: React.FC<CornerEditorProps> = ({ onCancel }) => {
  const {
    candidateImage,
    candidateCorners,
    setCandidateCorners,
    resetCornersToDetected,
    resetCornersToInset,
    applyPerspectiveCrop,
    isProcessing,
  } = useScanner();

  const containerRef = useRef<HTMLDivElement | null>(null);
  const [activeCorner, setActiveCorner] = useState<CornerKey | null>(null);
  const [containerRect, setContainerRect] = useState<{ width: number; height: number }>({
    width: 0,
    height: 0,
  });

  // Calculate image placement inside container under object-fit: contain
  const updateLayout = useCallback(() => {
    if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      setContainerRect({ width: rect.width, height: rect.height });
    }
  }, []);

  useEffect(() => {
    updateLayout();
    window.addEventListener('resize', updateLayout);
    return () => window.removeEventListener('resize', updateLayout);
  }, [updateLayout]);

  const imgW = candidateImage?.width || 1;
  const imgH = candidateImage?.height || 1;
  const contW = containerRect.width || 1;
  const contH = containerRect.height || 1;

  const imgAspect = imgW / imgH;
  const contAspect = contW / contH;

  let renderW = contW;
  let renderH = contH;
  let offsetX = 0;
  let offsetY = 0;

  if (imgAspect > contAspect) {
    renderW = contW;
    renderH = contW / imgAspect;
    offsetX = 0;
    offsetY = (contH - renderH) / 2;
  } else {
    renderH = contH;
    renderW = contH * imgAspect;
    offsetX = (contW - renderW) / 2;
    offsetY = 0;
  }

  // Convert normalized corner (0..1) to screen pixel position in container
  const toScreenPos = (p: Point): Point => ({
    x: offsetX + p.x * renderW,
    y: offsetY + p.y * renderH,
  });

  // Convert screen pixel position to normalized corner (0..1)
  const toNormalizedPos = (screenX: number, screenY: number): Point => {
    const relX = screenX - offsetX;
    const relY = screenY - offsetY;
    return {
      x: Math.max(0, Math.min(1, relX / renderW)),
      y: Math.max(0, Math.min(1, relY / renderH)),
    };
  };

  const handlePointerDown = (corner: CornerKey, e: React.PointerEvent) => {
    e.preventDefault();
    e.stopPropagation();
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    setActiveCorner(corner);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!activeCorner || !containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const clientX = e.clientX - rect.left;
    const clientY = e.clientY - rect.top;

    const norm = toNormalizedPos(clientX, clientY);

    setCandidateCorners((prev) => ({
      ...prev,
      [activeCorner]: norm,
    }));
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if (activeCorner) {
      try {
        (e.target as HTMLElement).releasePointerCapture(e.pointerId);
      } catch {
        // ignore
      }
      setActiveCorner(null);
    }
  };

  const pTL = toScreenPos(candidateCorners.tl);
  const pTR = toScreenPos(candidateCorners.tr);
  const pBR = toScreenPos(candidateCorners.br);
  const pBL = toScreenPos(candidateCorners.bl);

  // SVG mask to darken everything outside the quad
  const maskPath = `M 0 0 L ${contW} 0 L ${contW} ${contH} L 0 ${contH} Z M ${pTL.x} ${pTL.y} L ${pTR.x} ${pTR.y} L ${pBR.x} ${pBR.y} L ${pBL.x} ${pBL.y} Z`;

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-slate-950 text-white select-none overflow-hidden">
      {/* Top Header */}
      <div className="w-full flex items-center justify-between px-4 py-3 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 z-20">
        <button
          type="button"
          onClick={onCancel}
          className="flex items-center gap-1.5 text-sm font-medium text-slate-300 hover:text-white active:scale-95 transition"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Retake</span>
        </button>

        <span className="text-sm font-semibold tracking-tight text-slate-200">
          Adjust Document Corners
        </span>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={resetCornersToDetected}
            title="Auto-detect corners"
            className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-cyan-400 border border-slate-700 active:scale-95 transition"
            aria-label="Auto detect corners"
          >
            <Sparkles className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={resetCornersToInset}
            title="Full frame"
            className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 active:scale-95 transition"
            aria-label="Full frame crop"
          >
            <Maximize2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Interactive Crop Viewport */}
      <div
        ref={containerRef}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        className="relative flex-1 w-full h-full flex items-center justify-center overflow-hidden touch-none"
      >
        {/* Source Image */}
        {candidateImage && (
          <img
            src={candidateImage.url}
            alt="Scan capture"
            className="w-full h-full object-contain pointer-events-none"
          />
        )}

        {/* SVG Mask and Quad Boundary */}
        {containerRect.width > 0 && (
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none"
            viewBox={`0 0 ${contW} ${contH}`}
          >
            {/* Outer dark vignette */}
            <path
              d={maskPath}
              fill="rgba(0, 0, 0, 0.55)"
              fillRule="evenodd"
            />

            {/* Document boundary line */}
            <polygon
              points={`${pTL.x},${pTL.y} ${pTR.x},${pTR.y} ${pBR.x},${pBR.y} ${pBL.x},${pBL.y}`}
              fill="rgba(6, 182, 212, 0.12)"
              stroke="#06B6D4"
              strokeWidth="2.5"
              strokeDasharray="4 2"
              strokeLinejoin="round"
            />
          </svg>
        )}

        {/* 4 Touch Drag Anchors */}
        {(
          [
            { key: 'tl', pos: pTL, label: 'Top Left' },
            { key: 'tr', pos: pTR, label: 'Top Right' },
            { key: 'br', pos: pBR, label: 'Bottom Right' },
            { key: 'bl', pos: pBL, label: 'Bottom Left' },
          ] as const
        ).map(({ key, pos, label }) => {
          const isActive = activeCorner === key;
          return (
            <div
              key={key}
              style={{
                transform: `translate3d(${pos.x - 24}px, ${pos.y - 24}px, 0)`,
              }}
              onPointerDown={(e) => handlePointerDown(key, e)}
              className="absolute top-0 left-0 w-12 h-12 flex items-center justify-center cursor-move touch-none z-30 group"
              aria-label={`Drag ${label} corner`}
            >
              {/* Outer touch highlight */}
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center transition-transform ${
                  isActive
                    ? 'scale-125 bg-cyan-500/30 ring-4 ring-cyan-400'
                    : 'bg-cyan-500/20 group-hover:scale-110'
                }`}
              >
                {/* Center pin disc */}
                <div className="w-5 h-5 rounded-full bg-white border-2 border-cyan-500 shadow-md flex items-center justify-center">
                  <div className="w-1.5 h-1.5 rounded-full bg-cyan-600" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom Action Footer */}
      <div className="w-full px-6 py-4 bg-slate-900/90 backdrop-blur-md border-t border-slate-800 flex items-center justify-between z-20">
        <button
          type="button"
          onClick={resetCornersToDetected}
          className="text-xs font-semibold text-slate-400 hover:text-slate-200 flex items-center gap-1 py-2 px-3 rounded-lg hover:bg-slate-800 transition"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          Reset Quad
        </button>

        <button
          type="button"
          onClick={applyPerspectiveCrop}
          disabled={isProcessing}
          className="py-3 px-6 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold flex items-center gap-2 shadow-lg shadow-indigo-600/30 transition disabled:opacity-50"
        >
          {isProcessing ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>Warping Document...</span>
            </>
          ) : (
            <>
              <Check className="w-4 h-4" />
              <span>Apply & Straighten</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};
