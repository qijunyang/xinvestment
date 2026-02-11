module.exports = {
  // ElastiCache for Memcached - Get endpoint from AWS Console
  // Example: xinvestment-session-stg.xxxxxx.cache.amazonaws.com
  sessionStore: {
    type: 'memcached',
    memcached: {
      enabled: true,
      host: 'xinvestment-session-stg.xxxxxx.cache.amazonaws.com',
      port: 11211,
      autoDiscovery: true  // Enable for automatic node discovery on scaling
    }
  },
  env: 'stg',
  port: 3001,
  database: {
    host: 'stg-db.example.com',
    name: 'todo_stg',
    password: '@password@'
  }
};
