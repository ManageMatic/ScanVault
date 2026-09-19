import { useState, useEffect, useCallback } from 'react';
import { getStorageQuotaInfo, type StorageUsageInfo } from '../services/storageService';

export function useStorageUsage() {
  const [info, setInfo] = useState<StorageUsageInfo>({
    usage: 0,
    quota: 0,
    available: 0,
    percentUsed: 0,
    isSupported: false,
    isPersisted: false,
  });
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getStorageQuotaInfo();
      setInfo(data);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return {
    ...info,
    isLoading,
    refresh,
  };
}
