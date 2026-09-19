import { Router, Request, Response } from 'express';
import { HealthResponse } from '@scanvault/shared';

export const healthRouter = Router();

healthRouter.get('/health', (_req: Request, res: Response<HealthResponse>) => {
  res.status(200).json({
    success: true,
    service: 'scanvault-api',
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});
