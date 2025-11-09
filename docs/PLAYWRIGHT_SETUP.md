# Playwright End-to-End Testing Setup

## Overview

Playwright is a modern end-to-end testing framework that allows you to test your web applications across multiple browsers (Chromium, Firefox, and WebKit) with a single API. This guide covers the setup and best practices for E2E testing in the ts-azure-health project.

## Table of Contents

- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Best Practices](#best-practices)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Installation

Playwright has already been installed in this project. If you need to reinstall or update:

```bash
cd frontend
npm install --save-dev @playwright/test
npx playwright install --with-deps
```

This installs:
- `@playwright/test` - The test runner and assertions library
- Browser binaries (Chromium, Firefox, WebKit)
- System dependencies required by the browsers

## Project Structure

```
frontend/
├── tests/                    # E2E test files
│   ├── example.spec.ts      # Basic homepage tests
│   └── api.spec.ts          # API route tests
├── playwright.config.ts     # Playwright configuration
├── playwright-report/       # HTML test reports (generated)
└── test-results/           # Test artifacts (generated)
```

## Configuration

The project uses a comprehensive Playwright configuration in `playwright.config.ts`:

### Key Configuration Options

**Test Directory**: `./tests` - All test files must end with `.spec.ts`

**Parallel Execution**: Tests run in parallel for faster execution

**Retries**: 
- CI: 2 retries on failure
- Local: 0 retries (fail fast for debugging)

**Workers**:
- CI: 1 worker (serial execution for stability)
- Local: All available CPU cores

**Base URL**: `http://localhost:3000` (configurable via `PLAYWRIGHT_BASE_URL`)

**Artifacts**:
- Screenshots: On failure only
- Videos: On retry/failure
- Traces: On first retry (for debugging)

### Browser Projects

The configuration includes multiple projects for comprehensive testing:

1. **Desktop Browsers**:
   - Chromium (Chrome/Edge)
   - Firefox
   - WebKit (Safari)

2. **Mobile Browsers**:
   - Mobile Chrome (Pixel 5 viewport)
   - Mobile Safari (iPhone 12 viewport)

### Web Server

Playwright automatically starts the Next.js dev server before running tests:

```typescript
webServer: {
  command: 'npm run dev',
  url: 'http://localhost:3000',
  reuseExistingServer: !process.env.CI,
}
```

## Running Tests

### Available Scripts

```bash
# Run all tests (headless)
npm run test:e2e

# Run tests with UI mode (interactive)
npm run test:e2e:ui

# Run tests in headed mode (see browser)
npm run test:e2e:headed

# Run tests in debug mode (step through)
npm run test:e2e:debug

# Show HTML test report
npm run test:e2e:report

# Generate tests using codegen
npm run test:e2e:codegen
```

### Running Specific Tests

```bash
# Run a single test file
npx playwright test tests/example.spec.ts

# Run tests matching a pattern
npx playwright test --grep "API"

# Run tests in a specific browser
npx playwright test --project=chromium

# Run tests in multiple browsers
npx playwright test --project=chromium --project=firefox
```

### Debug Mode

Playwright's debug mode allows you to step through tests:

```bash
npm run test:e2e:debug

# Or debug a specific test
npx playwright test tests/example.spec.ts --debug
```

**Debugging Features**:
- Step through each action
- Pick locators interactively
- See actionability logs
- Explore object values

### UI Mode

UI mode provides an interactive interface for running and debugging tests:

```bash
npm run test:e2e:ui
```

**Features**:
- Run/debug tests visually
- Time travel through test execution
- Inspect DOM snapshots
- View network requests
- See console logs

## Writing Tests

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';

test('describe what the test does', async ({ page }) => {
  // Navigate to page
  await page.goto('/');
  
  // Interact with elements
  await page.click('button');
  
  // Assert expectations
  await expect(page).toHaveTitle(/Expected Title/);
});
```

### Test Organization

```typescript
test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup before each test
    await page.goto('/');
  });

  test('specific behavior 1', async ({ page }) => {
    // Test implementation
  });

  test('specific behavior 2', async ({ page }) => {
    // Test implementation
  });
});
```

### Selecting Elements

Playwright recommends user-facing locators:

```typescript
// By role (preferred)
await page.getByRole('button', { name: 'Submit' });
await page.getByRole('heading', { level: 1 });

// By label (for form fields)
await page.getByLabel('Email address');

// By placeholder
await page.getByPlaceholder('Enter your email');

// By text content
await page.getByText('Welcome');

// By test ID (when semantic locators aren't available)
await page.getByTestId('submit-button');
```

### Common Actions

```typescript
// Navigation
await page.goto('/about');
await page.goBack();
await page.reload();

// Clicking
await page.click('button');
await page.getByRole('button', { name: 'Submit' }).click();

// Typing
await page.fill('input[name="email"]', 'user@example.com');
await page.type('input[name="password"]', 'secret');

// Selecting
await page.selectOption('select[name="country"]', 'USA');

// Checking
await page.check('input[type="checkbox"]');
await page.uncheck('input[type="checkbox"]');

// Waiting
await page.waitForSelector('.loaded');
await page.waitForLoadState('networkidle');
await page.waitForTimeout(1000); // Use sparingly!
```

### Assertions

```typescript
// Page assertions
await expect(page).toHaveTitle('Home');
await expect(page).toHaveURL(/dashboard/);

// Element assertions
await expect(page.getByRole('heading')).toBeVisible();
await expect(page.getByText('Error')).toBeHidden();
await expect(page.getByLabel('Email')).toHaveValue('user@example.com');
await expect(page.getByRole('button')).toBeEnabled();
await expect(page.getByRole('button')).toBeDisabled();

// Text assertions
await expect(page.getByRole('alert')).toContainText('Success');
await expect(page.getByRole('status')).toHaveText('Online');

// Count assertions
await expect(page.getByRole('listitem')).toHaveCount(5);
```

### API Testing

```typescript
test('API endpoint returns correct data', async ({ request }) => {
  const response = await request.get('/api/data');
  
  expect(response.ok()).toBeTruthy();
  expect(response.status()).toBe(200);
  
  const data = await response.json();
  expect(data).toHaveProperty('id');
  expect(data.name).toBe('Expected Name');
});
```

### Authentication & Setup

For tests requiring authentication:

```typescript
// Setup file: tests/auth.setup.ts
import { test as setup } from '@playwright/test';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', 'user@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  // Save authenticated state
  await page.context().storageState({ 
    path: 'playwright/.auth/user.json' 
  });
});

// In playwright.config.ts
projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  {
    name: 'chromium',
    use: { 
      ...devices['Desktop Chrome'],
      storageState: 'playwright/.auth/user.json',
    },
    dependencies: ['setup'],
  },
]
```

### Visual Regression Testing

```typescript
test('visual regression', async ({ page }) => {
  await page.goto('/');
  
  // Take screenshot
  await expect(page).toHaveScreenshot('homepage.png');
  
  // Compare specific element
  const header = page.getByRole('banner');
  await expect(header).toHaveScreenshot('header.png');
});
```

## Best Practices

### 1. Use User-Facing Locators

❌ **Avoid**:
```typescript
await page.click('#submit-btn');
await page.click('.btn-primary');
```

✅ **Prefer**:
```typescript
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByLabel('Email').fill('user@example.com');
```

### 2. Wait for Elements Properly

❌ **Avoid arbitrary timeouts**:
```typescript
await page.waitForTimeout(5000);
```

✅ **Use auto-waiting**:
```typescript
// Playwright auto-waits for most actions
await page.click('button'); // Waits for button to be visible and enabled

// Explicit waiting when needed
await page.waitForSelector('.loaded');
await page.waitForLoadState('networkidle');
```

### 3. Keep Tests Independent

Each test should be able to run independently:

```typescript
test.describe('User Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Fresh setup for each test
    await page.goto('/dashboard');
  });

  test('can view profile', async ({ page }) => {
    // Independent test
  });

  test('can edit settings', async ({ page }) => {
    // Independent test
  });
});
```

### 4. Use Page Object Model for Complex Pages

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Log in' }).click();
  }
}

// In test
import { LoginPage } from './pages/LoginPage';

test('user can login', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.navigate();
  await loginPage.login('user@example.com', 'password');
  await expect(page).toHaveURL('/dashboard');
});
```

### 5. Test Data Management

```typescript
// fixtures/testData.ts
export const testUsers = {
  admin: {
    email: 'admin@example.com',
    password: 'admin123',
  },
  user: {
    email: 'user@example.com',
    password: 'user123',
  },
};

// In test
import { testUsers } from '../fixtures/testData';

test('admin can access admin panel', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', testUsers.admin.email);
  await page.fill('[name="password"]', testUsers.admin.password);
  // ...
});
```

### 6. Parallel Execution Considerations

```typescript
// Run tests in serial when they depend on shared state
test.describe.configure({ mode: 'serial' });

test.describe('Sequential tests', () => {
  test('step 1', async ({ page }) => {
    // First step
  });

  test('step 2', async ({ page }) => {
    // Depends on step 1
  });
});
```

### 7. Network Mocking

```typescript
test('handles API errors gracefully', async ({ page }) => {
  // Mock API failure
  await page.route('/api/data', route => {
    route.fulfill({
      status: 500,
      body: JSON.stringify({ error: 'Internal Server Error' }),
    });
  });

  await page.goto('/');
  await expect(page.getByText('Error loading data')).toBeVisible();
});
```

### 8. Mobile Testing

```typescript
test.use({ ...devices['iPhone 12'] });

test('mobile navigation works', async ({ page }) => {
  await page.goto('/');
  
  // Mobile-specific interactions
  await page.getByRole('button', { name: 'Menu' }).click();
  await expect(page.getByRole('navigation')).toBeVisible();
});
```

## CI/CD Integration

### GitHub Actions

A GitHub Actions workflow will be created in `.github/workflows/playwright.yml`:

```yaml
name: Playwright Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci
      
      - name: Install Playwright Browsers
        working-directory: ./frontend
        run: npx playwright install --with-deps
      
      - name: Run Playwright tests
        working-directory: ./frontend
        run: npm run test:e2e
        env:
          PLAYWRIGHT_BASE_URL: http://localhost:3000
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: frontend/playwright-report/
          retention-days: 30
```

### Environment Variables

Set these in your CI environment:

```bash
# Base URL for tests
PLAYWRIGHT_BASE_URL=http://localhost:3000

# Azure credentials (if testing with real Azure services)
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
```

## Troubleshooting

### Tests Fail on CI but Pass Locally

**Common causes**:
1. Timing issues - CI is slower
2. Different screen sizes
3. Missing environment variables

**Solutions**:
```typescript
// Increase timeout for CI
test.setTimeout(process.env.CI ? 60000 : 30000);

// Wait for network to be idle
await page.waitForLoadState('networkidle');

// Use consistent viewport
test.use({ viewport: { width: 1280, height: 720 } });
```

### Element Not Found

```typescript
// Check if element exists before interacting
const button = page.getByRole('button', { name: 'Submit' });
await expect(button).toBeVisible();
await button.click();

// Use waitFor for dynamic content
await page.waitForSelector('.dynamic-content');
```

### Flaky Tests

```typescript
// Add explicit waits
await page.waitForLoadState('networkidle');

// Wait for specific conditions
await page.waitForFunction(() => document.readyState === 'complete');

// Retry assertions
await expect(async () => {
  const text = await page.textContent('.status');
  expect(text).toBe('Ready');
}).toPass({ timeout: 10000 });
```

### Debugging Tips

```bash
# Run with UI mode for visual debugging
npm run test:e2e:ui

# Run in headed mode to see browser
npm run test:e2e:headed

# Use debug mode to step through
npm run test:e2e:debug

# Generate trace on failure
npx playwright test --trace on
npx playwright show-trace trace.zip
```

## Additional Resources

### Official Documentation
- [Playwright Documentation](https://playwright.dev/)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [API Reference](https://playwright.dev/docs/api/class-playwright)

### Next.js Specific
- [Testing Next.js with Playwright](https://nextjs.org/docs/testing#playwright)
- [Next.js Examples](https://github.com/vercel/next.js/tree/canary/examples/with-playwright)

### Community
- [Playwright Discord](https://aka.ms/playwright/discord)
- [GitHub Discussions](https://github.com/microsoft/playwright/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/playwright)

## Next Steps

1. ✅ Install Playwright and dependencies
2. ✅ Create configuration file
3. ✅ Add example tests
4. ✅ Configure npm scripts
5. ⏭️ Set up CI/CD workflow (see next todo)
6. ⏭️ Write tests for your specific features
7. ⏭️ Integrate with existing test suite
8. ⏭️ Set up visual regression testing (if needed)

## Quick Reference

### Most Common Commands

```bash
# Run all tests
npm run test:e2e

# Interactive UI mode (recommended for development)
npm run test:e2e:ui

# Debug a specific test
npx playwright test tests/example.spec.ts --debug

# Update snapshots
npx playwright test --update-snapshots

# Generate tests interactively
npm run test:e2e:codegen
```

### Test Selection

```bash
# Single file
npx playwright test example.spec.ts

# By test name
npx playwright test -g "should login"

# Single browser
npx playwright test --project=chromium

# Multiple browsers
npx playwright test --project=chromium --project=firefox
```

---

**Note**: This setup follows Playwright best practices and is optimized for the ts-azure-health project structure. Adjust configuration as needed for your specific requirements.
