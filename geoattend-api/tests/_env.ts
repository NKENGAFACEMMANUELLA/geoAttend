// Imported first by tests that touch src/utils/time.ts (needs environment variables).
process.env.DATABASE_URL ??= 'postgresql://test:test@localhost:5432/test';
process.env.JWT_SECRET ??= 'x'.repeat(40);
process.env.TIMEZONE ??= 'Africa/Douala';
