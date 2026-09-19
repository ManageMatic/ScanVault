/**
 * Standard API Success Response wrapper
 */
export interface ApiSuccessResponse<T> {
  success: true;
  data: T;
}

/**
 * Standard API Error Response wrapper
 */
export interface ApiErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

/**
 * Unified API Response type
 */
export type ApiResponse<T> = ApiSuccessResponse<T> | ApiErrorResponse;

/**
 * API Health Check response structure
 */
export interface HealthResponse {
  success: true;
  service: 'scanvault-api';
  status: 'ok';
  timestamp?: string;
  version?: string;
}
