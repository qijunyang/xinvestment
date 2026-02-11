# E2E Tests

End-to-end tests for the xinvestment application using Playwright.

## Overview

This directory contains E2E tests that verify the complete user workflows including:
- **Login**: User authentication and session management
- **Logout**: Session termination and cleanup
- **Navigation**: Page routing and navigation between views

## Running E2E Tests

### Setup Test Credentials

**Option 1: Using .env.test file (Local Development)**
```bash
# Copy the example file from e2e folder
cp e2e/.env.test.example e2e/.env.test

# Edit e2e/.env.test and set your credentials
TEST_USERNAME=your_username
TEST_PASSWORD=your_password
```

**Option 2: Using Environment Variables (CI/CD)**
```bash
# Linux/Mac
export TEST_USERNAME=your_username
export TEST_PASSWORD=your_password
npm run test:e2e

# Windows PowerShell
$env:TEST_USERNAME='your_username'
$env:TEST_PASSWORD='your_password'
npm run test:e2e

# Windows CMD
set TEST_USERNAME=your_username
set TEST_PASSWORD=your_password
npm run test:e2e
```

**Option 3: Inline with Command (One-time)**
```bash
# Linux/Mac
TEST_USERNAME=john TEST_PASSWORD=secret123 npm run test:e2e

# Windows PowerShell
$env:TEST_USERNAME='john'; $env:TEST_PASSWORD='secret123'; npm run test:e2e
```

### Install Playwright browsers (first time only)
```bash
npx playwright install
```

### Run all E2E tests
```bash
npm run test:e2e
# Or directly with config path:
npx playwright test --config=e2e/playwright.config.js
```

### Run E2E tests in UI mode (interactive)
```bash
npm run test:e2e:ui
```

### Run specific test file
```bash
npx playwright test --config=e2e/playwright.config.js e2e/login.spec.js
```

### Run tests in headed mode (see browser)
```bash
npx playwright test --config=e2e/playwright.config.js --headed
```

### Debug tests
```bash
npx playwright test --config=e2e/playwright.config.js --debug
```

## Test Structure

- `login.spec.js` - Tests for login functionality
  - Login page display
  - Invalid credentials handling
  - Successful login flow
  - Session persistence
  - Protected route access

- `logout.spec.js` - Tests for logout functionality
  - Logout from different pages
  - Session cleanup
  - Confirmation messages
  - Duplicate logout handling

- `navigation.spec.js` - Tests for navigation
  - Menu visibility
  - Page navigation
  - Active link highlighting
  - Browser history navigation
  - Direct URL access
  - 404 handling

## Configuration

E2E test configuration is in [e2e/playwright.config.js](playwright.config.js).

Key settings:
- **Base URL**: http://localhost:3000
- **Browsers**: Chromium, Firefox, WebKit
- **Auto-start**: Dev server starts automatically before tests
- **Screenshots**: Captured on test failure
- **Tracing**: Enabled on first retry

## Best Practices

1. **Test isolation**: Each test starts fresh with login
2. **Selectors**: Use semantic selectors (text, role, accessible names)
3. **Assertions**: Use Playwright's auto-waiting assertions
4. **Screenshots**: Automatically captured on failure
5. **Parallel execution**: Tests run in parallel by default

## Viewing Test Reports

After running tests, view the HTML report:
```bash
npx playwright show-report
```

## CI/CD Integration

The tests are configured to run in CI with:
- 2 retries on failure
- Single worker (sequential execution)
- Strict mode (no `.only()` allowed)

### GitHub Actions Example
```yaml
- name: Run E2E Tests
  env:
    TEST_USERNAME: ${{ secrets.TEST_USERNAME }}
    TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}
  run: |
    npm run test:e2e
```

### GitLab CI Example
```yaml
e2e-tests:
  script:
    - export TEST_USERNAME=$TEST_USERNAME
    - export TEST_PASSWORD=$TEST_PASSWORD
    - npm run test:e2e
  variables:
    TEST_USERNAME: $TEST_USERNAME
    TEST_PASSWORD: $TEST_PASSWORD
```

### Azure DevOps Example
```yaml
- script: |
    npm run test:e2e
  env:
    TEST_USERNAME: $(TEST_USERNAME)
    TEST_PASSWORD: $(TEST_PASSWORD)
```
