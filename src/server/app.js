const crypto = require('crypto');
const express = require('express');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const authController = require('./controllers/authController');
const userFeaturesRoutes = require('./routes/userFeaturesRoutes');
const householdRoutes = require('./routes/householdRoutes');
const { initializeApp } = require('./init');
const authMiddleware = require('./middleware/authMiddleware');
const sessionMiddleware = require('./middleware/sessionMiddleware');
const { logger, httpLogger, setRequestContext, clearRequestContext } = require('./log/logger');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from public
app.use(express.static(path.join(__dirname, '..', '..', 'public')));

// Start server only after config is loaded
async function startServer() {
  try {
    const config = await initializeApp();
    
    // Apply session middleware with config
    app.use(sessionMiddleware(config));

    app.use((req, res, next) => {
      const existingRequestId = req.get('x-request-id');
      const requestId = existingRequestId || crypto.randomUUID();
      req.requestId = requestId;
      res.set('x-request-id', requestId);
      const userId = req.user?.userId;

      setRequestContext({ requestId, userId });
      res.on('finish', () => {
        clearRequestContext();
      });
      next();
    });

    app.use(httpLogger);

    // Public API routes
    app.get('/api/health', (req, res) => {
      const appEnv = config.env?.app_env || config.env || 'dev';
      res.status(200).json({ status: 'OK', message: 'Server is running', env: appEnv });
    });

    app.post('/api/auth/login', authController.login);
    app.get('/api/auth/status', authController.getAuthStatus);

    // Serve login page at root and /login
    app.get('/', (req, res) => {
      res.sendFile(path.join(__dirname, '..', '..', 'public', 'login', 'index.html'));
    });

    app.get('/login', (req, res) => {
      res.sendFile(path.join(__dirname, '..', '..', 'public', 'login', 'index.html'));
    });

    // Serve home page
    app.get('/home', (req, res) => {
      res.sendFile(path.join(__dirname, '..', '..', 'public', 'home', 'index.html'));
    });

    // Auth middleware for protected API routes
    app.use('/api', authMiddleware);

    // Protected API routes
    app.use('/api/auth', authRoutes);
    app.use('/api/features', userFeaturesRoutes);
    app.use('/api/households', householdRoutes);

    // Error handling middleware
    app.use((err, req, res, next) => {
      logger.error(err.stack || err.message);
      res.status(500).json({ error: err.message || 'Internal Server Error' });
    });

    // 404 handler
    app.use((req, res) => {
      res.status(404).json({ error: 'Route not found' });
    });

    const PORT = config.port || process.env.PORT || 3000;
    app.listen(PORT, () => {
      const appEnv = config.env?.app_env || config.env || 'dev';
      logger.info(`Server is running on port ${PORT} (Environment: ${appEnv})`);
      logger.info(`Session cookie name: xinvestment-session-${appEnv}`);
      logger.info(`Login page: http://localhost:${PORT}/login/`);
    });
  } catch (error) {
    logger.error(`Failed to start server: ${error.message}`);
    process.exit(1);
  }
}

startServer();
