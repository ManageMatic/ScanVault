import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { hashPassword, verifyPassword, generateToken, hashToken } from '../src/lib/auth.js';
import { env } from '../src/config/env.js';

describe('Authentication Unit & Cryptography Helpers', () => {
  it('hashes passwords and verifies them correctly', async () => {
    const raw = 'SuperSecret123!';
    const hash = await hashPassword(raw);

    expect(hash).not.toBe(raw);
    expect(hash.startsWith('$2')).toBe(true);

    const match = await verifyPassword(raw, hash);
    expect(match).toBe(true);

    const wrong = await verifyPassword('WrongPassword', hash);
    expect(wrong).toBe(false);
  });

  it('generates high-entropy tokens and produces consistent SHA-256 hashes', () => {
    const token = generateToken(32);
    expect(token).toHaveLength(64); // 32 bytes hex encoded

    const hash1 = hashToken(token);
    const hash2 = hashToken(token);

    expect(hash1).toHaveLength(64);
    expect(hash1).toBe(hash2);
    expect(hash1).not.toBe(token);
  });
});

describe('Auth API Endpoints', () => {
  const app = createApp();
  const testEmail = `test_${Date.now()}@example.com`;
  const testPassword = 'Password123!';
  let sessionCookie = '';

  it('POST /api/v1/auth/register registers a new user and sets session cookie', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: testEmail,
        password: testPassword,
        name: 'Test Engineer',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(testEmail);
    expect(res.body.data.user.name).toBe('Test Engineer');
    expect(res.body.data.user).not.toHaveProperty('passwordHash');

    const cookies = res.headers['set-cookie'];
    expect(cookies).toBeDefined();
    const cookieHeader = Array.isArray(cookies) ? cookies.join('; ') : cookies;
    expect(cookieHeader).toContain('scanvault_session=');
    expect(cookieHeader).toContain('HttpOnly');
    sessionCookie = cookieHeader;
  });

  it('POST /api/v1/auth/register rejects duplicate email', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: testEmail,
        password: testPassword,
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('EMAIL_ALREADY_EXISTS');
  });

  it('POST /api/v1/auth/login logs in with valid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testEmail,
        password: testPassword,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(testEmail);

    const cookies = res.headers['set-cookie'];
    expect(cookies).toBeDefined();
    sessionCookie = Array.isArray(cookies) ? cookies.join('; ') : cookies;
  });

  it('POST /api/v1/auth/login rejects incorrect password', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testEmail,
        password: 'IncorrectPassword',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('GET /api/v1/auth/me returns current authenticated user', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Cookie', sessionCookie);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(testEmail);
  });

  it('GET /api/v1/auth/me returns 401 when no session cookie is provided', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/v1/auth/forgot-password issues a reset token', async () => {
    const res = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ email: testEmail });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.devResetToken).toBeDefined();

    const token = res.body.devResetToken;

    // Reset password
    const newPassword = 'NewPassword456!';
    const resetRes = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({ token, password: newPassword });

    expect(resetRes.status).toBe(200);
    expect(resetRes.body.success).toBe(true);

    // Verify login with new password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: testEmail, password: newPassword });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.success).toBe(true);
  });

  it('POST /api/v1/auth/logout terminates session and clears cookie', async () => {
    const res = await request(app)
      .post('/api/v1/auth/logout')
      .set('Cookie', sessionCookie);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const cookies = res.headers['set-cookie'];
    expect(cookies).toBeDefined();
    const cookieHeader = Array.isArray(cookies) ? cookies.join('; ') : cookies;
    expect(cookieHeader).toContain('scanvault_session=;');
  });

  it('GET /api/v1/auth/google generates state and redirects to Google OAuth authorization URL', async () => {
    const res = await request(app).get('/api/v1/auth/google');
    expect(res.status).toBe(302);
    expect(res.headers.location).toContain('accounts.google.com/o/oauth2/v2/auth');
    expect(res.headers.location).toContain('client_id=');
    expect(res.headers.location).toContain('redirect_uri=');

    const cookies = res.headers['set-cookie'];
    expect(cookies).toBeDefined();
    const cookieHeader = Array.isArray(cookies) ? cookies.join('; ') : cookies;
    expect(cookieHeader).toContain('scanvault_oauth_state=');
  });

  it('GET /api/v1/auth/google/callback redirects to client on state mismatch', async () => {
    const res = await request(app).get('/api/v1/auth/google/callback');
    expect(res.status).toBe(302);
    expect(res.headers.location).toBe(`${env.CLIENT_URL}/login?error=oauth_state_mismatch`);
  });

  it('GET /api/v1/auth/google/callback redirects to client on Google denial error', async () => {
    const res = await request(app).get('/api/v1/auth/google/callback?error=access_denied');
    expect(res.status).toBe(302);
    expect(res.headers.location).toBe(`${env.CLIENT_URL}/login?error=google_oauth_denied`);
  });
});
