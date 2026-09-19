export interface Point {
  x: number;
  y: number;
}

export interface QuadCorners {
  tl: Point; // Top-Left (0..1 normalized or image pixels)
  tr: Point; // Top-Right
  br: Point; // Bottom-Right
  bl: Point; // Bottom-Left
}

export type ScannerStep =
  | 'camera'
  | 'editing-corners'
  | 'page-preview'
  | 'page-manager'
  | 'saving';

export type CameraStatus =
  | 'idle'
  | 'requesting-permission'
  | 'camera-ready'
  | 'capturing'
  | 'permission-denied'
  | 'camera-unavailable'
  | 'camera-busy'
  | 'unsupported-browser'
  | 'error';

export interface CameraCapabilities {
  hasTorch: boolean;
  isTorchOn: boolean;
  hasZoom: boolean;
  minZoom: number;
  maxZoom: number;
  currentZoom: number;
  hasMultipleCameras: boolean;
  facingMode: 'environment' | 'user';
}

export interface ScannerPage {
  id: string;
  originalBlob: Blob;
  processedBlob: Blob;
  thumbnailBlob: Blob;
  originalUrl: string;
  processedUrl: string;
  thumbnailUrl: string;
  width: number;
  height: number;
  corners: QuadCorners;
  rotation: number; // 0, 90, 180, 270
  createdAt: Date;
}

export interface ScannerSession {
  pages: ScannerPage[];
  activePageIndex: number;
  step: ScannerStep;
}
