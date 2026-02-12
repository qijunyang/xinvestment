const session = require('express-session');
const { logger } = require('../log/logger');

/**
 * In-memory session store compatible with express-session
 * Stores user sessions in memory
 * Note: For production, use a persistent store like redis or database
 */
class MemorySessionStore extends session.Store {
  constructor() {
    super();
    this.sessions = {};
    // Cleanup expired sessions every 10 minutes
    this.cleanupInterval = setInterval(() => this.cleanup(), 10 * 60 * 1000);
  }

  /**
   * Get session by ID
   * @param {string} sid - Session ID
   * @param {function} callback - Callback(err, session)
   */
  get(sid, callback) {
    try {
      const session = this.sessions[sid];
      if (session && session.expiresAt > Date.now()) {
        return callback(null, session.data);
      }
      // Session expired or not found
      return callback(null, null);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Set/create a session
   * @param {string} sid - Session ID
   * @param {object} session - Session data
   * @param {function} callback - Callback(err)
   */
  set(sid, session, callback) {
    try {
      // Calculate expiry time from maxAge
      const maxAge = session.cookie?.maxAge || 24 * 60 * 60 * 1000;
      const expiresAt = Date.now() + maxAge;
      
      this.sessions[sid] = {
        data: session,
        createdAt: new Date(),
        expiresAt: expiresAt
      };
      
      callback(null);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Destroy a session
   * @param {string} sid - Session ID
   * @param {function} callback - Callback(err)
   */
  destroy(sid, callback) {
    try {
      delete this.sessions[sid];
      callback(null);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Get all sessions (optional)
   * @param {function} callback - Callback(err, sessions)
   */
  all(callback) {
    try {
      const sessions = Object.keys(this.sessions)
        .map(sid => ({ 
          sid, 
          ...this.sessions[sid] 
        }))
        .filter(session => session.expiresAt > Date.now());
      
      callback(null, sessions);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Clear all sessions (optional)
   * @param {function} callback - Callback(err)
   */
  clear(callback) {
    try {
      this.sessions = {};
      callback(null);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Get session count (optional)
   * @param {function} callback - Callback(err, count)
   */
  length(callback) {
    try {
      const count = Object.keys(this.sessions)
        .filter(sid => this.sessions[sid].expiresAt > Date.now())
        .length;
      
      callback(null, count);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Touch/update session (update expiration time)
   * Required by express-session for rolling sessions
   * @param {string} sid - Session ID
   * @param {object} session - Session data
   * @param {function} callback - Callback(err)
   */
  touch(sid, session, callback) {
    try {
      if (this.sessions[sid]) {
        // Update expiration time based on cookie maxAge
        const maxAge = session.cookie?.maxAge || 24 * 60 * 60 * 1000;
        this.sessions[sid].expiresAt = Date.now() + maxAge;
      }
      callback(null);
    } catch (err) {
      callback(err);
    }
  }

  /**
   * Cleanup expired sessions
   */
  cleanup() {
    const now = Date.now();
    const expiredSessions = Object.keys(this.sessions)
      .filter(sid => this.sessions[sid].expiresAt <= now);
    
    expiredSessions.forEach(sid => {
      delete this.sessions[sid];
    });

    if (expiredSessions.length > 0) {
      logger.info(`[SessionStore] Cleaned up ${expiredSessions.length} expired sessions`);
    }
  }

  /**
   * Shutdown the store and cleanup resources
   */
  shutdown() {
    clearInterval(this.cleanupInterval);
  }
}

// Create and export a single instance
const store = new MemorySessionStore();

module.exports = {
  getStore: () => store,
  
  // Legacy methods for backward compatibility
  createSession: (userData) => {
    const sessionId = `sess_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    store.set(sessionId, userData, () => {});
    return sessionId;
  },
  
  getSession: (sessionId) => {
    let result = null;
    store.get(sessionId, (err, data) => {
      if (err) return;
      result = data ? { data } : null;
    });
    return result;
  },
  
  destroySession: (sessionId) => {
    store.destroy(sessionId, () => {});
  }
};

