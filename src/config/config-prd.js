module.exports = {
  // ElastiCache for Memcached - Get endpoint from AWS Console
  // Example: xinvestment-session-prd.xxxxxx.cache.amazonaws.com
  sessionStore: {
    type: 'memcached',
    memcached: {
      enabled: true,
      host: 'xinvestment-session-prd.xxxxxx.cache.amazonaws.com',
      port: 11211,
      autoDiscovery: true  // Enable for automatic node discovery on scaling
    }
  },
  env: {
    app_env: 'prd'
  },
  port: 3001,
  database: {
    host: 'prd-db.example.com',
    name: 'todo_prd',
    password: '@password@'
  },
  logLevel: 'error'
};
