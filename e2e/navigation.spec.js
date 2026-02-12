/**
 * E2E tests for navigation functionality
 */

const { test, expect } = require('@playwright/test');
const testConfig = require('./config');

test.describe('Navigation Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    const { username, password } = testConfig.getTestCredentials();
    await page.goto('/login');
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/home/);
  });

  test('should display navigation menu', async ({ page }) => {
    // Check for navigation elements
    const nav = page.locator('nav.navigation');
    await expect(nav).toBeVisible();
    
    // Check for navigation links (Dashboard, Health Check)
    const dashboardLink = page.locator('a.nav-link:has-text("Dashboard")');
    await expect(dashboardLink).toBeVisible();
  });

  test('should navigate to dashboard view', async ({ page }) => {
    // Navigate back to dashboard
    const dashboardLink = page.locator('a.nav-link:has-text("Dashboard")');
    await dashboardLink.click();
    await page.waitForTimeout(300);
    
    // Still on /home URL, but Dashboard component should be visible
    await expect(page).toHaveURL(/\/home/);
    await expect(page.locator('text=Welcome to Xinvestment')).toBeVisible();
  });

  test('should navigate to health check view', async ({ page }) => {
    const healthLink = page.locator('a.nav-link:has-text("Health Check")');
    await healthLink.click();
    await page.waitForTimeout(300);
    
    // URL stays /home but Health Check component loads
    await expect(page).toHaveURL(/\/home/);
    await expect(page.locator('text=Server Health Check')).toBeVisible();
  });

  test('should highlight active navigation item', async ({ page }) => {
    // Navigate to health check
    const healthLink = page.locator('a.nav-link:has-text("Health Check")');
    await healthLink.click();
    await page.waitForTimeout(300);
    
    // Active link should have 'active' class
    const activeHealthLink = page.locator('a.nav-link.active:has-text("Health Check")');
    await expect(activeHealthLink).toBeVisible();
  });

  test('should stay on same page with client-side navigation', async ({ page }) => {
    const initialURL = page.url();
    
    // Navigate to health check (client-side)
    const healthLink = page.locator('a.nav-link:has-text("Health Check")');
    await healthLink.click();
    await page.waitForTimeout(300);
    
    // URL should remain /home throughout
    await expect(page).toHaveURL(initialURL);
  });

  test('should switch between views smoothly', async ({ page }) => {
    // Navigate to dashboard
    const dashboardLink = page.locator('a.nav-link:has-text("Dashboard")');
    await dashboardLink.click();
    await page.waitForTimeout(300);
    await expect(page.locator('text=Welcome to Xinvestment')).toBeVisible();

    // Navigate to health check
    const healthLink = page.locator('a.nav-link:has-text("Health Check")');
    await healthLink.click();
    await page.waitForTimeout(300);
    await expect(page.locator('text=Server Health Check')).toBeVisible();
  });

  test('should maintain navigation across different views', async ({ page }) => {
    // Navigation should be visible
    const nav = page.locator('nav.navigation');
    await expect(nav).toBeVisible();

    // Navigate to health check view
    const healthLink = page.locator('a.nav-link:has-text("Health Check")');
    await healthLink.click();
    await page.waitForTimeout(300);
    await expect(nav).toBeVisible();
  });

  test('should handle direct URL access', async ({ page }) => {
    // Directly access home page via URL
    await page.goto('/home');
    await expect(page).toHaveURL(/\/home/);
    
    // Navigation should work
    const nav = page.locator('nav.navigation');
    await expect(nav).toBeVisible();
    
    const dashboardLink = page.locator('a.nav-link:has-text("Dashboard")');
    await expect(dashboardLink).toBeVisible();
  });

  test('should handle 404 not found pages', async ({ page }) => {
    const response = await page.goto('/nonexistent-page');
    
    // Should return 404 status
    expect(response.status()).toBe(404);
  });

  test('should support keyboard navigation', async ({ page }) => {
    const firstLink = page.locator('a.nav-link').first();
    await firstLink.focus();
    
    // Should be focused
    await expect(firstLink).toBeFocused();
    
    // Tab to next element
    await page.keyboard.press('Tab');
    
    // Should focus next link
    const focusedElement = page.locator(':focus');
    await expect(focusedElement).toBeVisible();
  });
});
