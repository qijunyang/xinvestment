/**
 * Test suite for session store
 * Tests in-memory session store operations
 */

const sessionStore = require('../../src/middleware/sessionStore');

describe('SessionStore', () => {
  let store;

  beforeEach(() => {
    // Get a fresh store instance for each test
    store = sessionStore.getStore();
  });

  describe('get', () => {
    it('should return null for non-existent session', (done) => {
      store.get('non-existent-id', (err, session) => {
        expect(err).toBeNull();
        expect(session).toBeNull();
        done();
      });
    });

    it('should return session data if it exists', (done) => {
      const sessionData = { userId: 'test-user', username: 'testuser', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('test-session', sessionData, (err) => {
        expect(err).toBeNull();
        
        store.get('test-session', (err, data) => {
          expect(err).toBeNull();
          expect(data).toBeDefined();
          expect(data.userId).toBe('test-user');
          expect(data.username).toBe('testuser');
          done();
        });
      });
    });
  });

  describe('set', () => {
    it('should store session data', (done) => {
      const sessionData = { userId: 'user123', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('session123', sessionData, (err) => {
        expect(err).toBeNull();
        done();
      });
    });

    it('should update existing session', (done) => {
      const sessionData = { userId: 'user123', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('session456', sessionData, (err) => {
        const updatedData = { userId: 'user456', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
        
        store.set('session456', updatedData, (err) => {
          store.get('session456', (err, data) => {
            expect(data.userId).toBe('user456');
            done();
          });
        });
      });
    });
  });

  describe('destroy', () => {
    it('should remove session', (done) => {
      const sessionData = { userId: 'user789', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('session789', sessionData, (err) => {
        store.destroy('session789', (err) => {
          expect(err).toBeNull();
          
          store.get('session789', (err, data) => {
            expect(data).toBeNull();
            done();
          });
        });
      });
    });
  });

  describe('touch', () => {
    it('should update session expiration', (done) => {
      const sessionData = { userId: 'user999', cookie: { maxAge: 1000 } };
      
      store.set('session999', sessionData, (err) => {
        const newSession = { userId: 'user999', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
        
        store.touch('session999', newSession, (err) => {
          expect(err).toBeNull();
          
          store.get('session999', (err, data) => {
            expect(data).toBeDefined();
            done();
          });
        });
      });
    });
  });

  describe('length', () => {
    it('should return session count', (done) => {
      const sessionData1 = { userId: 'user1', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      const sessionData2 = { userId: 'user2', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('session-1', sessionData1, (err) => {
        store.set('session-2', sessionData2, (err) => {
          store.length((err, count) => {
            expect(err).toBeNull();
            expect(count).toBeGreaterThanOrEqual(2);
            done();
          });
        });
      });
    });
  });

  describe('clear', () => {
    it('should clear all sessions', (done) => {
      const sessionData = { userId: 'user123', cookie: { maxAge: 24 * 60 * 60 * 1000 } };
      
      store.set('session-clear-1', sessionData, (err) => {
        store.clear((err) => {
          expect(err).toBeNull();
          
          store.length((err, count) => {
            expect(count).toBe(0);
            done();
          });
        });
      });
    });
  });
});
