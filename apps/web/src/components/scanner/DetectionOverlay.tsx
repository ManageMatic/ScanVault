import React from 'react';
import type { QuadCorners } from '../../lib/scanner/scannerTypes';

interface DetectionOverlayProps {
  corners: QuadCorners | null;
  className?: string;
}

/**
 * Renders an animated SVG quadrilateral overlay over the live camera preview.
 * Coordinates are normalized (0..1) and scale to SVG viewBox (0 0 100 100).
 */
export const DetectionOverlay: React.FC<DetectionOverlayProps> = ({ corners, className = '' }) => {
  if (!corners) {
    return (
      <div className={`absolute inset-0 pointer-events-none flex items-center justify-center ${className}`}>
        {/* Subtle document frame guide */}
        <div className="w-[82%] h-[78%] border-2 border-dashed border-white/30 rounded-2xl animate-pulse" />
      </div>
    );
  }

  const pTL = { x: corners.tl.x * 100, y: corners.tl.y * 100 };
  const pTR = { x: corners.tr.x * 100, y: corners.tr.y * 100 };
  const pBR = { x: corners.br.x * 100, y: corners.br.y * 100 };
  const pBL = { x: corners.bl.x * 100, y: corners.bl.y * 100 };

  const pathD = `M ${pTL.x} ${pTL.y} L ${pTR.x} ${pTR.y} L ${pBR.x} ${pBR.y} L ${pBL.x} ${pBL.y} Z`;

  return (
    <div className={`absolute inset-0 pointer-events-none ${className}`}>
      <svg
        className="w-full h-full"
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <linearGradient id="quadGlow" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#06B6D4" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#10B981" stopOpacity="0.8" />
          </linearGradient>
          <filter id="glow">
            <feGaussianBlur stdDeviation="0.8" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Shaded highlight on detected document */}
        <path
          d={pathD}
          fill="rgba(6, 182, 212, 0.15)"
          stroke="url(#quadGlow)"
          strokeWidth="0.8"
          strokeLinejoin="round"
          strokeLinecap="round"
          filter="url(#glow)"
        />

        {/* Corner anchor circles */}
        {[pTL, pTR, pBR, pBL].map((p, idx) => (
          <g key={idx}>
            <circle cx={p.x} cy={p.y} r="1.5" fill="#FFFFFF" />
            <circle cx={p.x} cy={p.y} r="1.5" fill="none" stroke="#06B6D4" strokeWidth="0.4" />
          </g>
        ))}
      </svg>
    </div>
  );
};
