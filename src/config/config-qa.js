module.exports = {
  env: {
    app_env: 'qa'
  },
  port: 3001,
  database: {
    host: 'qa-db.example.com',
    name: 'todo_qa',
    password: '@password@'
  },
  debug: true,
  // ElastiCache for Memcached - Get endpoint from AWS Console
  // Example: xinvestment-session-qa.xxxxxx.cache.amazonaws.com
  sessionStore: {
    type: 'memcached',
    memcached: {
      enabled: true,
      host: 'xinvestment-session-qa.xxxxxx.cache.amazonaws.com',
      port: 11211,
      autoDiscovery: true  // Enable for automatic node discovery on scaling
    }
  }
};
