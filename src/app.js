const express = require('express');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const userFeaturesRoutes = require('./routes/userFeaturesRoutes');
const householdRoutes = require('./routes/householdRoutes');
const { initializeApp } = require('./init');
const sessionMiddleware = require('./middleware/sessionMiddleware');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from client folder
app.use(express.static(path.join(__dirname, 'client')));

// Start server only after config is loaded
async function startServer() {
  try {
    const config = await initializeApp();
    
    // Apply session middleware with config
    app.use(sessionMiddleware(config));
    
    // Auth routes (includes login/logout)
    app.use('/api/auth', authRoutes);
    
    // User Features routes (public)
    app.use('/api/features', userFeaturesRoutes);
    
    // Household routes (protected with auth)
    app.use('/api/households', householdRoutes);

    // Health check endpoint (no auth required)
    app.get('/api/health', (req, res) => {
      res.status(200).json({ status: 'OK', message: 'Server is running', env: config.env });
    });

    // Serve login page at root and /login
    app.get('/', (req, res) => {
      res.sendFile(path.join(__dirname, 'client', 'login', 'index.html'));
    });

    app.get('/login', (req, res) => {
      res.sendFile(path.join(__dirname, 'client', 'login', 'index.html'));
    });

    // Serve home page (protected - HomeApp.vue checks authentication)
    app.get('/home', (req, res) => {
      res.sendFile(path.join(__dirname, 'client', 'home', 'index.html'));
    });

    // Error handling middleware
    app.use((err, req, res, next) => {
      console.error(err.stack);
      res.status(500).json({ error: err.message || 'Internal Server Error' });
    });

    // 404 handler
    app.use((req, res) => {
      res.status(404).json({ error: 'Route not found' });
    });

    const PORT = config.port || process.env.PORT || 3000;
    app.listen(PORT, () => {
      console.log(`✓ Server is running on port ${PORT} (Environment: ${config.env})`);
      console.log(`✓ Session cookie name: xinvestment-session-${config.env}`);
      console.log(`✓ Login page: http://localhost:${PORT}/login/`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
}

startServer();
