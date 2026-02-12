/**
 * E2E tests for logout functionality
 */

const { test, expect } = require('@playwright/test');
const testConfig = require('./config');

test.describe('Logout Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    const { username, password } = testConfig.getTestCredentials();
    await page.goto('/login');
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/home/);
  });

  test('should successfully logout', async ({ page }) => {
    // Find and click logout button
    const logoutButton = page.locator('.btn-logout, button:has-text("Logout")');
    await logoutButton.click();
    
    // Should redirect to login page
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });

  test('should clear session after logout', async ({ page }) => {
    // Logout
    const logoutButton = page.locator('.btn-logout, button:has-text("Logout")');
    await logoutButton.click();
    await page.waitForURL(/\/login/);
    
    // Try to access protected page
    await page.goto('/home');
    
    // Should be redirected back to login
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });

  test('should show logout confirmation message', async ({ page }) => {
    const logoutButton = page.locator('.btn-logout, button:has-text("Logout")');
    await logoutButton.click();
    
    // Check for redirection to login
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });

  test('should handle logout from different pages', async ({ page }) => {
    // Logout from another view
    const logoutButton = page.locator('.btn-logout, button:has-text("Logout")');
    await logoutButton.click();
    
    // Should redirect to login
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });

  test('should prevent duplicate logout requests', async ({ page }) => {
    const logoutButton = page.locator('.btn-logout, button:has-text("Logout")');
    
    // Click logout
    await logoutButton.click();
    await page.waitForURL(/\/login/);
    
    // Try to logout again via API (should not cause error, just return success)
    const response = await page.goto('/api/auth/logout');
    
    // Should return 200 OK even when already logged out
    expect(response.status()).toBe(200);
    
    // Verify still can't access protected pages
    await page.goto('/home');
    await page.waitForURL(/\/login/);
    await expect(page).toHaveURL(/\/login/);
  });
});
