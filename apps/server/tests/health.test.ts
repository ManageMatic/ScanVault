import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';

describe('Backend Health & Error Endpoints', () => {
  const app = createApp();

  it('GET /api/v1/health returns success and service name', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      success: true,
      service: 'scanvault-api',
      status: 'ok',
    });
  });

  it('GET /unknown-route returns 404 with standardized error response', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.status).toBe(404);
    expect(res.body).toMatchObject({
      success: false,
      error: {
        code: 'ROUTE_NOT_FOUND',
      },
    });
  });
});
