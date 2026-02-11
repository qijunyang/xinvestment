/**
 * E2E tests for login functionality
 */

const { test, expect } = require('@playwright/test');
const testConfig = require('./config');

test.describe('Login Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('should display login page', async ({ page }) => {
    await expect(page).toHaveTitle(/Login/i);
    await expect(page.locator('#username')).toBeVisible();
    await expect(page.locator('#password')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });

  test('should accept any credentials for demo purposes', async ({ page }) => {
    // App accepts any username/password since it's a demo without real auth
    const { username, password } = testConfig.getTestCredentials();
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');
    
    // Should successfully login and redirect to home
    await page.waitForURL(/\/home/, { timeout: 5000 });
    await expect(page).toHaveURL(/\/home/);
  });

  test('should successfully login with valid credentials', async ({ page }) => {
    const { username, password } = testConfig.getTestCredentials();
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');
    
    // After successful login, should redirect to home/dashboard
    await page.waitForURL(/\/home/);
    await expect(page).toHaveURL(/\/home/);
  });

  test('should prevent access to protected pages when not logged in', async ({ page }) => {
    await page.goto('/home');
    
    // Should redirect to login
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });

  test('should remember user session after page reload', async ({ page }) => {
    // Login first
    const { username, password } = testConfig.getTestCredentials();
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/home/);
    
    // Reload page
    await page.reload();
    
    // Should still be logged in
    await expect(page).toHaveURL(/\/home/);
  });

  test('should validate required fields', async ({ page }) => {
    // Try to submit empty form
    await page.click('button[type="submit"]');
    
    // Check for HTML5 validation or custom validation messages
    const usernameInput = page.locator('#username');
    const passwordInput = page.locator('#password');
    
    await expect(usernameInput).toHaveAttribute('required', '');
    await expect(passwordInput).toHaveAttribute('required', '');
  });
});
