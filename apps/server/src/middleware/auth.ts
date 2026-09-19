import { Request, Response, NextFunction } from 'express';
import { validateSession, SESSION_COOKIE_NAME, SafeUser } from '../lib/session.js';
import { ApiErrorResponse } from '@scanvault/shared';

// Extend Express Request interface
/* eslint-disable @typescript-eslint/no-namespace */
declare global {
  namespace Express {
    interface Request {
      user?: SafeUser;
      sessionToken?: string;
    }
  }
}
/* eslint-enable @typescript-eslint/no-namespace */

/**
 * Middleware requiring an active valid session
 */
export async function requireAuth(
  req: Request,
  res: Response<ApiErrorResponse>,
  next: NextFunction
): Promise<void> {
  const rawToken = req.cookies?.[SESSION_COOKIE_NAME];

  if (!rawToken || typeof rawToken !== 'string') {
    res.status(401).json({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication required. Please sign in.',
      },
    });
    return;
  }

  try {
    const result = await validateSession(rawToken);

    if (!result) {
      res.status(401).json({
        success: false,
        error: {
          code: 'SESSION_EXPIRED',
          message: 'Your session has expired. Please sign in again.',
        },
      });
      return;
    }

    req.user = result.user;
    req.sessionToken = rawToken;
    next();
  } catch (error) {
    console.error('[ScanVault][AuthMiddleware] Error validating session:', error);
    res.status(401).json({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Invalid session.',
      },
    });
  }
}

/**
 * Optional authentication middleware for routes accessible by guests and users
 */
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const rawToken = req.cookies?.[SESSION_COOKIE_NAME];

  if (rawToken && typeof rawToken === 'string') {
    try {
      const result = await validateSession(rawToken);
      if (result) {
        req.user = result.user;
        req.sessionToken = rawToken;
      }
    } catch {
      // Ignore in optional auth
    }
  }

  next();
}
