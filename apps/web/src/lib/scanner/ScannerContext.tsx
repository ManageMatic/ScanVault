import {
  createContext,
  useContext,
  useState,
  useEffect,
  useRef,
  useCallback,
  ReactNode,
} from 'react';
import {
  startCameraStream,
  stopMediaStream,
  switchCameraDevice,
  toggleCameraTorch,
  captureFrameAsBlob,
} from './cameraService';
import {
  detectDocumentEdgesOnVideo,
  detectDocumentEdgesOnImage,
  getDefaultInsetCorners,
} from './detectionService';
import {
  transformPerspective,
  rotatePageImage,
  createPageThumbnail,
  validateImageBlob,
} from './perspectiveService';
import type {
  CameraCapabilities,
  CameraStatus,
  QuadCorners,
  ScannerPage,
  ScannerSession,
  ScannerStep,
} from './scannerTypes';
import { documentRepository } from '../db/repositories/documentRepository';
import { useAuth } from '../auth';

interface ScannerContextType {
  // State
  step: ScannerStep;
  cameraStatus: CameraStatus;
  capabilities: CameraCapabilities;
  session: ScannerSession;
  candidateImage: { blob: Blob; url: string; width: number; height: number } | null;
  candidateCorners: QuadCorners;
  detectedCorners: QuadCorners | null;
  liveCorners: QuadCorners | null;
  isProcessing: boolean;
  errorMessage: string | null;

  // Video Ref
  videoRef: React.RefObject<HTMLVideoElement | null>;

  // Camera Actions
  startCamera: () => Promise<void>;
  stopCamera: () => void;
  switchCamera: () => Promise<void>;
  toggleTorch: () => Promise<void>;

  // Workflow Actions
  captureFrame: () => Promise<void>;
  importImageFile: (file: File) => Promise<void>;
  setCandidateCorners: React.Dispatch<React.SetStateAction<QuadCorners>>;
  resetCornersToDetected: () => void;
  resetCornersToInset: () => void;
  applyPerspectiveCrop: () => Promise<void>;
  rotateCurrentPage: () => Promise<void>;
  retakeCurrentPage: () => void;
  addAnotherPage: () => void;
  goToStep: (step: ScannerStep) => void;
  setActivePageIndex: (index: number) => void;
  deletePage: (index: number) => void;
  movePage: (fromIndex: number, toIndex: number) => void;
  saveScanSession: (title: string, folderId?: string | null) => Promise<string>;
  resetSession: () => void;
}

const ScannerContext = createContext<ScannerContextType | undefined>(undefined);

export function ScannerProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const userId = user?.id || 'local-guest';

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const detectionAnimRef = useRef<number | null>(null);
  const isDetectingRef = useRef(false);

  const [step, setStep] = useState<ScannerStep>('camera');
  const [cameraStatus, setCameraStatus] = useState<CameraStatus>('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const [capabilities, setCapabilities] = useState<CameraCapabilities>({
    hasTorch: false,
    isTorchOn: false,
    hasZoom: false,
    minZoom: 1,
    maxZoom: 1,
    currentZoom: 1,
    hasMultipleCameras: false,
    facingMode: 'environment',
  });

  const [session, setSession] = useState<ScannerSession>({
    pages: [],
    activePageIndex: 0,
    step: 'camera',
  });

  const [candidateImage, setCandidateImage] = useState<{
    blob: Blob;
    url: string;
    width: number;
    height: number;
  } | null>(null);

  const [candidateCorners, setCandidateCorners] = useState<QuadCorners>(getDefaultInsetCorners());
  const [detectedCorners, setDetectedCorners] = useState<QuadCorners | null>(null);
  const [liveCorners, setLiveCorners] = useState<QuadCorners | null>(null);

  // Clean up object URLs tracked by pages
  const cleanupPages = (pages: ScannerPage[]) => {
    pages.forEach((p) => {
      try {
        if (p.originalUrl) URL.revokeObjectURL(p.originalUrl);
        if (p.processedUrl) URL.revokeObjectURL(p.processedUrl);
        if (p.thumbnailUrl) URL.revokeObjectURL(p.thumbnailUrl);
      } catch {
        // ignore
      }
    });
  };

  const cleanupCandidateImage = () => {
    if (candidateImage?.url) {
      try {
        URL.revokeObjectURL(candidateImage.url);
      } catch {
        // ignore
      }
      setCandidateImage(null);
    }
  };

  // Safe camera starter
  const startCamera = useCallback(async () => {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      setCameraStatus('unsupported-browser');
      setErrorMessage('Your browser does not support camera access. You can still import image files.');
      return;
    }

    setCameraStatus('requesting-permission');
    setErrorMessage(null);

    const result = await startCameraStream(capabilities.facingMode);

    if (result.success && result.stream) {
      streamRef.current = result.stream;
      if (videoRef.current) {
        videoRef.current.srcObject = result.stream;
        videoRef.current.play().catch(() => {
          // Autoplay policy fallback
        });
      }
      setCapabilities(result.capabilities);
      setCameraStatus('camera-ready');
    } else {
      setCameraStatus(result.status);
      setErrorMessage(result.error || 'Unable to access camera.');
    }
  }, [capabilities.facingMode]);

  const stopCamera = useCallback(() => {
    if (detectionAnimRef.current) {
      cancelAnimationFrame(detectionAnimRef.current);
      detectionAnimRef.current = null;
    }
    if (streamRef.current) {
      stopMediaStream(streamRef.current);
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setLiveCorners(null);
  }, []);

  // Switch camera front/back
  const switchCamera = useCallback(async () => {
    if (!streamRef.current) return;
    const nextFacing = capabilities.facingMode === 'environment' ? 'user' : 'environment';
    const result = await switchCameraDevice(streamRef.current, nextFacing);

    if (result.success && result.stream) {
      streamRef.current = result.stream;
      if (videoRef.current) {
        videoRef.current.srcObject = result.stream;
        videoRef.current.play().catch(() => {});
      }
      setCapabilities(result.capabilities);
      setCameraStatus('camera-ready');
    } else {
      setCameraStatus(result.status);
      setErrorMessage(result.error || 'Failed to switch camera.');
    }
  }, [capabilities.facingMode]);

  // Toggle flash torch
  const toggleTorch = useCallback(async () => {
    if (!streamRef.current) return;
    const nextTorch = !capabilities.isTorchOn;
    const success = await toggleCameraTorch(streamRef.current, nextTorch);
    if (success) {
      setCapabilities((prev) => ({ ...prev, isTorchOn: nextTorch }));
    }
  }, [capabilities.isTorchOn]);

  // Live edge detection loop (throttled ~8 FPS)
  useEffect(() => {
    if (step !== 'camera' || cameraStatus !== 'camera-ready') {
      if (detectionAnimRef.current) {
        cancelAnimationFrame(detectionAnimRef.current);
        detectionAnimRef.current = null;
      }
      return;
    }

    let lastRunTime = 0;
    const intervalMs = 120; // ~8 FPS detection loop

    const detectLoop = (timestamp: number) => {
      if (timestamp - lastRunTime > intervalMs) {
        lastRunTime = timestamp;
        if (videoRef.current && !isDetectingRef.current) {
          isDetectingRef.current = true;
          try {
            const detected = detectDocumentEdgesOnVideo(videoRef.current);
            setLiveCorners(detected);
          } catch {
            // Ignore frame read transient errors
          } finally {
            isDetectingRef.current = false;
          }
        }
      }
      detectionAnimRef.current = requestAnimationFrame(detectLoop);
    };

    detectionAnimRef.current = requestAnimationFrame(detectLoop);

    return () => {
      if (detectionAnimRef.current) {
        cancelAnimationFrame(detectionAnimRef.current);
        detectionAnimRef.current = null;
      }
    };
  }, [step, cameraStatus]);

  // Stop camera when leaving camera step or unmounting
  useEffect(() => {
    if (step !== 'camera') {
      stopCamera();
    }
  }, [step, stopCamera]);

  useEffect(() => {
    return () => {
      stopCamera();
      cleanupCandidateImage();
      cleanupPages(session.pages);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Capture current camera frame
  const captureFrame = useCallback(async () => {
    if (!videoRef.current) return;
    setIsProcessing(true);
    try {
      const blob = await captureFrameAsBlob(videoRef.current, 0.95);
      const validation = await validateImageBlob(blob);
      if (!validation.valid) {
        throw new Error('Captured frame could not be decoded.');
      }

      cleanupCandidateImage();
      const url = URL.createObjectURL(blob);
      setCandidateImage({
        blob,
        url,
        width: validation.width,
        height: validation.height,
      });

      // Use live corners if valid, otherwise detect on blob
      let corners = liveCorners;
      if (!corners) {
        corners = await detectDocumentEdgesOnImage(blob);
      }
      const safeCorners = corners || getDefaultInsetCorners();
      setDetectedCorners(safeCorners);
      setCandidateCorners(safeCorners);

      stopCamera();
      setStep('editing-corners');
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : 'Failed to capture frame.');
    } finally {
      setIsProcessing(false);
    }
  }, [liveCorners, stopCamera]);

  // Import image file from device gallery / picker
  const importImageFile = useCallback(async (file: File) => {
    setIsProcessing(true);
    setErrorMessage(null);
    try {
      const validation = await validateImageBlob(file);
      if (!validation.valid) {
        throw new Error('Selected file is not a valid or decodable image.');
      }

      cleanupCandidateImage();
      const url = URL.createObjectURL(file);
      setCandidateImage({
        blob: file,
        url,
        width: validation.width,
        height: validation.height,
      });

      const corners = await detectDocumentEdgesOnImage(file);
      const safeCorners = corners || getDefaultInsetCorners();
      setDetectedCorners(safeCorners);
      setCandidateCorners(safeCorners);

      stopCamera();
      setStep('editing-corners');
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : 'Failed to import image.');
    } finally {
      setIsProcessing(false);
    }
  }, [stopCamera]);

  const resetCornersToDetected = useCallback(() => {
    if (detectedCorners) {
      setCandidateCorners(detectedCorners);
    } else {
      setCandidateCorners(getDefaultInsetCorners());
    }
  }, [detectedCorners]);

  const resetCornersToInset = useCallback(() => {
    setCandidateCorners(getDefaultInsetCorners());
  }, []);

  // Apply homography perspective warp on candidate image
  const applyPerspectiveCrop = useCallback(async () => {
    if (!candidateImage) return;
    setIsProcessing(true);
    setErrorMessage(null);

    try {
      const warped = await transformPerspective(candidateImage.blob, candidateCorners, 0.94);
      const thumbnailBlob = await createPageThumbnail(warped.blob, 320, 0.82);

      const processedUrl = URL.createObjectURL(warped.blob);
      const thumbnailUrl = URL.createObjectURL(thumbnailBlob);
      const originalUrl = candidateImage.url;

      const newPage: ScannerPage = {
        id: `scan_page_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        originalBlob: candidateImage.blob,
        processedBlob: warped.blob,
        thumbnailBlob,
        originalUrl,
        processedUrl,
        thumbnailUrl,
        width: warped.width,
        height: warped.height,
        corners: candidateCorners,
        rotation: 0,
        createdAt: new Date(),
      };

      setSession((prev) => {
        const nextPages = [...prev.pages, newPage];
        return {
          pages: nextPages,
          activePageIndex: nextPages.length - 1,
          step: 'page-preview',
        };
      });

      setStep('page-preview');
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : 'Perspective transformation failed.');
    } finally {
      setIsProcessing(false);
    }
  }, [candidateImage, candidateCorners]);

  // Rotate active page 90 degrees
  const rotateCurrentPage = useCallback(async () => {
    const activePage = session.pages[session.activePageIndex];
    if (!activePage) return;

    setIsProcessing(true);
    try {
      const newRotation = (activePage.rotation + 90) % 360;
      const rotated = await rotatePageImage(activePage.processedBlob, 90, 0.94);
      const thumbnailBlob = await createPageThumbnail(rotated.blob, 320, 0.82);

      if (activePage.processedUrl) URL.revokeObjectURL(activePage.processedUrl);
      if (activePage.thumbnailUrl) URL.revokeObjectURL(activePage.thumbnailUrl);

      const processedUrl = URL.createObjectURL(rotated.blob);
      const thumbnailUrl = URL.createObjectURL(thumbnailBlob);

      const updatedPage: ScannerPage = {
        ...activePage,
        processedBlob: rotated.blob,
        thumbnailBlob,
        processedUrl,
        thumbnailUrl,
        width: rotated.width,
        height: rotated.height,
        rotation: newRotation,
      };

      setSession((prev) => {
        const nextPages = [...prev.pages];
        nextPages[prev.activePageIndex] = updatedPage;
        return { ...prev, pages: nextPages };
      });
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : 'Rotation failed.');
    } finally {
      setIsProcessing(false);
    }
  }, [session.pages, session.activePageIndex]);

  // Retake candidate or active page
  const retakeCurrentPage = useCallback(() => {
    cleanupCandidateImage();
    setStep('camera');
    startCamera();
  }, [startCamera]);

  // Add another page to multi-page document
  const addAnotherPage = useCallback(() => {
    cleanupCandidateImage();
    setStep('camera');
    startCamera();
  }, [startCamera]);

  const goToStep = useCallback((nextStep: ScannerStep) => {
    setStep(nextStep);
  }, []);

  const setActivePageIndex = useCallback((index: number) => {
    setSession((prev) => ({
      ...prev,
      activePageIndex: Math.max(0, Math.min(prev.pages.length - 1, index)),
    }));
  }, []);

  const deletePage = useCallback((index: number) => {
    setSession((prev) => {
      const pageToDelete = prev.pages[index];
      if (pageToDelete) {
        try {
          if (pageToDelete.originalUrl) URL.revokeObjectURL(pageToDelete.originalUrl);
          if (pageToDelete.processedUrl) URL.revokeObjectURL(pageToDelete.processedUrl);
          if (pageToDelete.thumbnailUrl) URL.revokeObjectURL(pageToDelete.thumbnailUrl);
        } catch {
          // ignore
        }
      }

      const nextPages = prev.pages.filter((_, i) => i !== index);
      const nextIndex = Math.max(0, Math.min(nextPages.length - 1, prev.activePageIndex >= nextPages.length ? nextPages.length - 1 : prev.activePageIndex));

      if (nextPages.length === 0) {
        setStep('camera');
      }

      return {
        pages: nextPages,
        activePageIndex: nextIndex,
        step: nextPages.length === 0 ? 'camera' : prev.step,
      };
    });
  }, []);

  const movePage = useCallback((fromIndex: number, toIndex: number) => {
    setSession((prev) => {
      if (fromIndex < 0 || fromIndex >= prev.pages.length || toIndex < 0 || toIndex >= prev.pages.length) {
        return prev;
      }
      const nextPages = [...prev.pages];
      const item = nextPages[fromIndex];
      if (!item) return prev;
      nextPages.splice(fromIndex, 1);
      nextPages.splice(toIndex, 0, item);
      return {
        ...prev,
        pages: nextPages,
        activePageIndex: toIndex,
      };
    });
  }, []);

  // Save full scanner session into Dexie IndexedDB Vault
  const saveScanSession = useCallback(
    async (title: string, folderId?: string | null): Promise<string> => {
      if (session.pages.length === 0) {
        throw new Error('No scanned pages to save.');
      }

      const firstPage = session.pages[0];
      if (!firstPage) {
        throw new Error('No valid scanned pages to save.');
      }

      setIsProcessing(true);
      setStep('saving');

      try {
        const docId = `doc_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        const fileId = `file_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        const thumbnailId = `thumb_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

        // Total file size across pages
        const totalSize = session.pages.reduce((sum, p) => sum + p.processedBlob.size, 0);

        // Primary representative file blob (first page for single or composite)
        const primaryBlob = firstPage.processedBlob;

        // Construct LocalDocument record
        const docRecord = {
          id: docId,
          userId,
          title: title.trim() || `Scan ${new Date().toLocaleDateString()}`,
          mimeType: 'image/jpeg',
          size: totalSize,
          pageCount: session.pages.length,
          folderId: folderId || null,
          favorite: false,
          status: 'ready' as const,
          createdAt: new Date(),
          updatedAt: new Date(),
          lastOpenedAt: new Date(),
          deletedAt: null,
          thumbnailId,
          source: 'scanned' as const,
          version: 1,
          tags: ['Scanned'],
          thumbnailColor: '#3B82F6',
        };

        // Construct LocalDocumentFile record
        const fileRecord = {
          id: fileId,
          documentId: docId,
          blob: primaryBlob,
          mimeType: 'image/jpeg',
          size: totalSize,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        // Construct LocalDocumentPage records
        const pageRecords = session.pages.map((p, index) => ({
          id: `page_${docId}_${index + 1}`,
          documentId: docId,
          pageNumber: index + 1,
          width: p.width,
          height: p.height,
          imageBlobId: fileId,
          thumbnailId,
          createdAt: p.createdAt,
          updatedAt: new Date(),
        }));

        // Construct LocalThumbnail record
        const thumbnailRecord = {
          id: thumbnailId,
          documentId: docId,
          blob: firstPage.thumbnailBlob,
          mimeType: 'image/jpeg',
          width: 320,
          height: Math.round((firstPage.height / firstPage.width) * 320),
          createdAt: new Date(),
        };

        // Save atomically into IndexedDB
        await documentRepository.createDocument(
          docRecord,
          fileRecord,
          pageRecords,
          thumbnailRecord
        );

        // Reset session on successful save
        cleanupPages(session.pages);
        setSession({ pages: [], activePageIndex: 0, step: 'camera' });
        setCandidateImage(null);
        setStep('camera');

        return docId;
      } finally {
        setIsProcessing(false);
      }
    },
    [session.pages, userId]
  );

  const resetSession = useCallback(() => {
    stopCamera();
    cleanupCandidateImage();
    cleanupPages(session.pages);
    setSession({ pages: [], activePageIndex: 0, step: 'camera' });
    setCandidateCorners(getDefaultInsetCorners());
    setDetectedCorners(null);
    setStep('camera');
  }, [stopCamera, session.pages]);

  return (
    <ScannerContext.Provider
      value={{
        step,
        cameraStatus,
        capabilities,
        session,
        candidateImage,
        candidateCorners,
        detectedCorners,
        liveCorners,
        isProcessing,
        errorMessage,
        videoRef,
        startCamera,
        stopCamera,
        switchCamera,
        toggleTorch,
        captureFrame,
        importImageFile,
        setCandidateCorners,
        resetCornersToDetected,
        resetCornersToInset,
        applyPerspectiveCrop,
        rotateCurrentPage,
        retakeCurrentPage,
        addAnotherPage,
        goToStep,
        setActivePageIndex,
        deletePage,
        movePage,
        saveScanSession,
        resetSession,
      }}
    >
      {children}
    </ScannerContext.Provider>
  );
}

export function useScanner() {
  const context = useContext(ScannerContext);
  if (!context) {
    throw new Error('useScanner must be used within a ScannerProvider');
  }
  return context;
}
