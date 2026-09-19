import { describe, it, expect } from 'vitest';
import { env } from '../src/config/env.js';

describe('Environment Configuration Validation', () => {
  it('loads valid environment variables', () => {
    expect(env).toBeDefined();
    expect(env.PORT).toBeGreaterThan(0);
    expect(typeof env.DATABASE_URL).toBe('string');
    expect(env.SESSION_SECRET.length).toBeGreaterThanOrEqual(16);
  });
});
