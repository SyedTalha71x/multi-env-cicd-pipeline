import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import { errorMiddleware, notFoundHandler } from './middleware/error.middleware.js';
import authRoutes from './routes/auth.routes.js'
import { specs } from './config/swagger.js';
import { configDotenv } from 'dotenv';
import logger from './config/logger.js';

configDotenv();


const app = express();

// Security middleware
app.use(helmet());
app.use(cors());
app.use(compression());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, 
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', limiter);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  next();
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
  });
});

app.use('/api/v1/auth', authRoutes);

app.use(notFoundHandler);

app.use(errorMiddleware);

export default app;