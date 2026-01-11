import app from './app.js';
import logger from './config/logger.js';
import { connectDatabase } from './config/db.js';

const PORT = process.env.PORT || 3000;

const gracefulShutdown = () => {
  logger.info('Received shutdown signal, closing server gracefully...');
  
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

const startServer = async () => {
  try {
    await connectDatabase();
    
    const server = app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
      logger.info(`API Documentation: http://localhost:${PORT}/api-docs`);
    });

    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);

    return server;
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

const server = await startServer();

export default server;