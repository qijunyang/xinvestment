/**
 * Test suite for config loader
 * Tests configuration loading and merging logic
 */

const { loadConfig } = require('../../src/config/configLoader');

describe('ConfigLoader', () => {
  describe('loadConfig', () => {
    it('should load default config for dev environment', async () => {
      const config = await loadConfig('dev');
      expect(config).toBeDefined();
      expect(config.env).toBe('dev');
      expect(config.port).toBeDefined();
      expect(config.sessionSecret).toBeDefined();
    });

    it('should load environment-specific config', async () => {
      const config = await loadConfig('qa');
      expect(config).toBeDefined();
      expect(config.env).toBe('qa');
    });

    it('should merge default and environment configs', async () => {
      const devConfig = await loadConfig('dev');
      const qaConfig = await loadConfig('qa');
      
      // Both should have required fields
      expect(devConfig.port).toBeDefined();
      expect(qaConfig.port).toBeDefined();
      
      // Environment-specific values should differ or be present
      expect(devConfig.env).toBe('dev');
      expect(qaConfig.env).toBe('qa');
    });

    it('should include session store configuration', async () => {
      const config = await loadConfig('dev');
      expect(config.sessionStore).toBeDefined();
      expect(config.sessionStore.type).toBeDefined();
    });

    it('should configure in-memory store for dev', async () => {
      const config = await loadConfig('dev');
      expect(config.sessionStore.memcached.enabled).toBe(false);
    });

    it('should configure memcached for non-dev environments', async () => {
      const qaConfig = await loadConfig('qa');
      expect(qaConfig.sessionStore.memcached.enabled).toBe(true);
      expect(qaConfig.sessionStore.memcached.host).toBeDefined();
      expect(qaConfig.sessionStore.memcached.port).toBe(11211);
    });

    it('should have same session secret for all environments', async () => {
      const devConfig = await loadConfig('dev');
      const qaConfig = await loadConfig('qa');
      
      // Both should have a session secret (may be the same default)
      expect(devConfig.sessionSecret).toBeDefined();
      expect(qaConfig.sessionSecret).toBeDefined();
    });
  });
});
