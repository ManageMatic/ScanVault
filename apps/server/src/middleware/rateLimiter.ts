import rateLimit from 'express-rate-limit';
import { ApiErrorResponse } from '@scanvault/shared';

/**
 * Rate limiter for sensitive authentication endpoints (login, register, forgot-password)
 * Limit: 50 requests per 15 minutes per IP
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many authentication attempts. Please try again in a few minutes.',
    },
  } as ApiErrorResponse,
});
