import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn', 'log'] });
  const configService = app.get(ConfigService);
  const logger = new Logger('NestApplication');

  // Seguridad: Helmet para headers HTTP
  app.use(helmet());

  // CORS Configuration
  const corsOrigin = configService.get('security.corsOrigin');
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization',
  });

  // Validación global de DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger/OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('Professional Backend API')
    .setDescription('API de ejemplo con arquitectura MVC profesional')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = configService.get('port') || 3000;
  await app.listen(port);
  logger.log(`✅ Aplicación escuchando en puerto ${port}`);
  logger.log(`📚 Documentación Swagger disponible en http://localhost:${port}/api/docs`);
}

bootstrap().catch(error => {
  console.error('Error al iniciar la aplicación:', error);
  process.exit(1);
});
