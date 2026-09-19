import { createApp } from './app.js';
import { env } from './config/env.js';
import { prisma } from './lib/prisma.js';

const app = createApp();

const server = app.listen(env.PORT, () => {
  console.log(`🚀 ScanVault Backend listening on http://localhost:${env.PORT}`);
  console.log(`📡 Health endpoint available at http://localhost:${env.PORT}/api/v1/health`);
  console.log(`🔒 Mode: ${env.NODE_ENV}`);
});

// Graceful shutdown handling
async function shutdown(signal: string) {
  console.log(`\n🛑 Received ${signal}. Shutting down gracefully...`);
  server.close(async () => {
    try {
      await prisma.$disconnect();
      console.log('✅ PostgreSQL disconnected.');
      process.exit(0);
    } catch (err) {
      console.error('Error during shutdown:', err);
      process.exit(1);
    }
  });

  // Force close after 10 seconds
  setTimeout(() => {
    console.error('⚠️ Forcefully terminating server after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
