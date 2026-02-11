const session = require('express-session');
const sessionStore = require('./sessionStore');

/**
 * Session middleware using express-session
 * Features:
 * - Signed and encrypted cookies
 * - HTTPOnly flag for security
 * - Secure flag for HTTPS (production)
 * - SameSite protection against CSRF
 * - Configurable session store: memory (dev) or memcached (prod)
 */
function sessionMiddleware(config) {
  const sessionCookieName = `xinvestment-session-${config.env}`;
  
  // Session secret for signing cookies - should be unique and strong
  // In production, this should come from environment variables
  const sessionSecret = config.sessionSecret || process.env.SESSION_SECRET || 'xinvestment-session-secret-key-change-in-production';
  
  // Select session store based on configuration
  let store;
  if (config.sessionStore?.type === 'memcached' && config.sessionStore?.memcached?.enabled) {
    // Use memcached for production environments (AWS ElastiCache)
    try {
      const Memcached = require('memcached');
      const memcachedConfig = config.sessionStore.memcached;
      
      // Create memcached client with auto-discovery for AWS ElastiCache
      // Note: Use the cluster configuration endpoint (not individual node addresses)
      // AWS ElastiCache will automatically discover all nodes when autodiscovery is enabled
      // Example endpoint: xinvestment-session-qa.xxxxxx.cache.amazonaws.com
      const memcachedClient = new Memcached([`${memcachedConfig.host}:${memcachedConfig.port}`], {
        maxValue: 1000000,
        timeout: 200,
        autodiscovery: memcachedConfig.autoDiscovery || false,  // AWS ElastiCache node auto-discovery
        retries: 3,                                              // Retry failed operations
        retry: 30000,                                            // Retry interval in ms
        maxConnections: 256                                      // Connection pooling for scalability
      });
      
      // Use memcached store
      const MemcachedStore = require('connect-memcached')(session);
      store = new MemcachedStore({ client: memcachedClient });
      
      const discoveryMsg = memcachedConfig.autoDiscovery ? ' (with AWS auto-discovery)' : '';
      console.log(`[SessionMiddleware] Using AWS ElastiCache memcached store: ${memcachedConfig.host}:${memcachedConfig.port}${discoveryMsg}`);
    } catch (err) {
      console.warn('[SessionMiddleware] ElastiCache memcached not available, falling back to memory store:', err.message);
      store = sessionStore.getStore();
    }
  } else {
    // Use in-memory store for development
    store = sessionStore.getStore();
    console.log('[SessionMiddleware] Using in-memory session store');
  }
  
  const sessionConfig = session({
    // Store configuration
    store: store,
    
    // Session settings
    name: sessionCookieName,
    secret: sessionSecret,
    resave: false,
    saveUninitialized: false,
    
    // Cookie settings
    cookie: {
      // Sign the cookie to prevent tampering
      signed: true,
      
      // HTTPOnly prevents JavaScript access to the cookie
      httpOnly: true,
      
      // Secure flag for HTTPS (enable in production)
      secure: config.env === 'production',
      
      // SameSite protection against CSRF attacks
      sameSite: 'strict',
      
      // Session timeout: 24 hours
      maxAge: 24 * 60 * 60 * 1000
    },
    
    // Session timeout settings
    rolling: true, // Reset expiration time on each request
    
    // Regenerate session id after login for security
    genid: (req) => {
      return require('crypto').randomBytes(16).toString('hex');
    }
  });

  // Return middleware that includes express-session + compatibility layer
  return (req, res, next) => {
    sessionConfig(req, res, () => {
      // Add backward compatibility: set req.user from req.session
      if (req.session && req.session.userId) {
        req.user = {
          userId: req.session.userId,
          username: req.session.username,
          loginTime: req.session.loginTime
        };
      }
      next();
    });
  };
}

module.exports = sessionMiddleware;

