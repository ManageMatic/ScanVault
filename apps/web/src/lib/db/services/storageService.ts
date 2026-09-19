export interface StorageUsageInfo {
  usage: number; // bytes
  quota: number; // bytes
  available: number; // bytes
  percentUsed: number;
  isSupported: boolean;
  isPersisted: boolean;
}

/**
 * Storage telemetry service using navigator.storage.estimate()
 */
export async function getStorageQuotaInfo(): Promise<StorageUsageInfo> {
  const fallback: StorageUsageInfo = {
    usage: 0,
    quota: 0,
    available: 0,
    percentUsed: 0,
    isSupported: false,
    isPersisted: false,
  };

  if (typeof navigator === 'undefined' || !navigator.storage) {
    return fallback;
  }

  try {
    let isPersisted = false;
    if (typeof navigator.storage.persisted === 'function') {
      isPersisted = await navigator.storage.persisted();
    }

    if (typeof navigator.storage.estimate === 'function') {
      const estimate = await navigator.storage.estimate();
      const usage = estimate.usage || 0;
      const quota = estimate.quota || 0;
      const available = Math.max(0, quota - usage);
      const percentUsed = quota > 0 ? Math.round((usage / quota) * 100) : 0;

      return {
        usage,
        quota,
        available,
        percentUsed,
        isSupported: true,
        isPersisted,
      };
    }

    return fallback;
  } catch {
    return fallback;
  }
}

/**
 * Request persistent browser storage to prevent eviction
 */
export async function requestPersistentStorage(): Promise<boolean> {
  if (
    typeof navigator !== 'undefined' &&
    navigator.storage &&
    typeof navigator.storage.persist === 'function'
  ) {
    try {
      return await navigator.storage.persist();
    } catch {
      return false;
    }
  }
  return false;
}
