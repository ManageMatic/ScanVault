import { Request, Response, NextFunction } from 'express';
import { ApiErrorResponse } from '@scanvault/shared';
import { env } from '../config/env.js';

export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = 'AppError';
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  const isAppError = err instanceof AppError;
  const statusCode = isAppError ? err.statusCode : 500;
  const code = isAppError ? err.code : 'INTERNAL_SERVER_ERROR';
  const message = isAppError
    ? err.message
    : env.NODE_ENV === 'production'
    ? 'An unexpected error occurred. Please try again later.'
    : err.message;

  const response: ApiErrorResponse = {
    success: false,
    error: {
      code,
      message,
      ...(isAppError && err.details ? { details: err.details } : {}),
    },
  };

  if (!isAppError && env.NODE_ENV !== 'test') {
    console.error('Unhandled Error:', err);
  }

  res.status(statusCode).json(response);
}

export function notFoundHandler(_req: Request, res: Response): void {
  const response: ApiErrorResponse = {
    success: false,
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: 'The requested API route does not exist.',
    },
  };
  res.status(404).json(response);
}
