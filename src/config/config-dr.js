module.exports = {
  // ElastiCache for Memcached - Get endpoint from AWS Console
  // Example: xinvestment-session-dr.xxxxxx.cache.amazonaws.com
  sessionStore: {
    type: 'memcached',
    memcached: {
      enabled: true,
      host: 'xinvestment-session-dr.xxxxxx.cache.amazonaws.com',
      port: 11211,
      autoDiscovery: true  // Enable for automatic node discovery on scaling
    }
  },
    env: {
      app_env: 'dr'
    },
  port: 3001,
  database: {
    host: 'dr-db.example.com',
    name: 'todo_dr',
    password: '@password@'
  },
  logLevel: 'error'
};
