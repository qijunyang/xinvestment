# Unit Tests

This directory contains unit tests for the Xinvestment backend application.

## Running Tests

### Run all tests once
```bash
npm test
```

### Run tests in watch mode
```bash
npm run test:watch
```
Watch mode automatically re-runs tests when you modify test or source files.

### Generate coverage report
```bash
npm run test:coverage
```
Generates a coverage report showing which parts of the code are tested.

## Test Structure

Tests mirror the backend structure under `src/server`:

- **configLoader.test.js** - Tests for configuration loading and merging
  - Loading default config
  - Loading environment-specific configs
  - Config merging logic
  - Session store configuration

- **sessionStore.test.js** - Tests for in-memory session store
  - Getting sessions
  - Setting sessions
  - Destroying sessions
  - Touching (updating) session expiration
  - Session management

- **authController.test.js** - Tests for authentication logic
  - Login validation
  - Password checking
  - Login success flow
  - Get current user
  - Logout flow
  - Session destruction

- **userFeaturesService.test.js** - Tests for feature management
  - Retrieving all features
  - Getting user-specific features
  - Fetching features by ID

## Test Framework

This project uses [Jest](https://jestjs.io/) as the test framework.

### Jest Configuration

Jest is configured in `package.json` with:
- **testEnvironment**: `node` (Node.js environment, not browser)
- **testMatch**: `**/test/**/*.test.js` (files ending in `.test.js`)
- **Coverage threshold**: 50% minimum for all metrics
- **Coverage collection**: Excludes client files and Vue components

## Adding New Tests

1. Create a new file under `test/server/...` (matching `src/server/...`)
2. Use the existing test structure as a reference
3. Run `npm test` to verify

### Test Template

```javascript
/**
 * Test suite for [module name]
 * Tests [what functionality]
 */

const moduleToTest = require('../../../src/server/path/to/module');

describe('ModuleName', () => {
  it('should do something specific', () => {
    // Arrange
    const input = 'test data';
    
    // Act
    const result = moduleToTest.someFunction(input);
    
    // Assert
    expect(result).toBe('expected value');
  });
});
```

## Best Practices

1. **Descriptive test names** - Use `should...` format
2. **One assertion per test** - Keep tests focused
3. **Arrange-Act-Assert** - Clear test structure
4. **Mock external dependencies** - Don't test external systems
5. **Test edge cases** - Null, empty values, errors
6. **Keep tests isolated** - Tests shouldn't depend on each other
7. **Use beforeEach/afterEach** - For setup and cleanup

## Continuous Integration

Tests should be run automatically in CI/CD pipelines:

```bash
npm test -- --coverage --watchAll=false
```

This runs all tests once with coverage reporting, suitable for CI environments.
