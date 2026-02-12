module.exports = {
  env: {
    app_env: process.env.APP_ENV || 'dev'
  },
  port: 3000,
  database: {
    port: 27017
  },
  debug: false,
  logLevel: 'info',
  // Session configuration
  sessionSecret: process.env.SESSION_SECRET || 'xinvestment-session-secret-key-change-in-production',
  // Note: In production, set SESSION_SECRET environment variable to a strong random string
  // Example: SESSION_SECRET=$(openssl rand -hex 32) npm start
  
  // Session store configuration
  sessionStore: {
    type: 'memory', // 'memory' | 'memcached'
    memcached: {
      enabled: false,
      host: 'localhost',
      port: 11211
    }
  }
};
