const { loadConfig } = require('./config/configLoader');
const { logger } = require('./log/logger');

/**
 * Initialize application with loaded configuration
 * Must be called before starting the app to ensure all secrets are loaded
 * @param {string} env - The environment name (defaults to APP_ENV or 'dev')
 * @returns {Promise<object>} - The initialized configuration object
 */
async function initializeApp(env) {
  const rawEnv = env || process.env.APP_ENV || 'dev';
  const environment = String(rawEnv).toLowerCase();
  
  try {
    logger.info('🚀 Initializing application...');
    const config = await loadConfig(environment);
    logger.info('✓ Application configuration loaded successfully');
    return config;
  } catch (error) {
    logger.error('✗ Application initialization failed:', error.message);
    process.exit(1); // Exit if config cannot be loaded
  }
}

module.exports = {
  initializeApp
};
