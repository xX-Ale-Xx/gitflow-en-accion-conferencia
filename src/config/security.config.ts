import { registerAs } from '@nestjs/config';

export default registerAs('security', () => ({
  jwtSecret: process.env.JWT_SECRET || 'super-secret-key',
  jwtExpiration: process.env.JWT_EXPIRATION || '3600',
  corsOrigin: (process.env.CORS_ORIGIN || 'http://localhost:3000').split(','),
}));
