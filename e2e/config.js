/**
 * E2E Test Configuration
 * Supports environment variables and CLI arguments
 */

// Load environment variables from .env.test file if it exists
const fs = require('fs');
const path = require('path');

const envTestPath = path.join(__dirname, '.env.test');

if (fs.existsSync(envTestPath)) {
  const envContent = fs.readFileSync(envTestPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, ...valueParts] = trimmed.split('=');
      const value = valueParts.join('=').trim();
      if (key && value && !process.env[key]) {
        process.env[key] = value;
      }
    }
  });
}

module.exports = {
  // Test credentials - can be overridden via environment variables
  testUser: {
    username: process.env.TEST_USERNAME || 'john',
    password: process.env.TEST_PASSWORD || 'testpass123'
  },
  
  // Test configuration
  baseURL: process.env.TEST_BASE_URL || 'http://localhost:3000',
  timeout: parseInt(process.env.TEST_TIMEOUT || '30000', 10),
  
  // Helper function to get credentials from env or defaults
  getTestCredentials() {
    return {
      username: this.testUser.username,
      password: this.testUser.password
    };
  }
};
