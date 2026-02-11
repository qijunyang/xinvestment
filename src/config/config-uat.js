module.exports = {
  // ElastiCache for Memcached - Get endpoint from AWS Console
  // Example: xinvestment-session-uat.xxxxxx.cache.amazonaws.com
  sessionStore: {
    type: 'memcached',
    memcached: {
      enabled: true,
      host: 'xinvestment-session-uat.xxxxxx.cache.amazonaws.com',
      port: 11211,
      autoDiscovery: true  // Enable for automatic node discovery on scaling
    }
  },
  env: 'uat',
  port: 3001,
  database: {
    host: 'uat-db.example.com',
    name: 'todo_uat',
    password: '@password@'
  },
  logLevel: 'warn'
};
