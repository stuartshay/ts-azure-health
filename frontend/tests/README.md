# Frontend Testing

## Playwright E2E Tests

End-to-end tests using Playwright are configured for this project. See [PLAYWRIGHT_SETUP.md](../docs/PLAYWRIGHT_SETUP.md) for complete documentation.

### Quick Start

```bash
# Run all tests (headless)
npm run test:e2e

# Interactive UI mode (recommended for development)
npm run test:e2e:ui

# Run with visible browser
npm run test:e2e:headed

# Debug mode (step through tests)
npm run test:e2e:debug

# View last test report
npm run test:e2e:report

# Generate tests interactively
npm run test:e2e:codegen
```

### Test Structure

```
tests/
├── example.spec.ts    # Homepage and navigation tests
└── api.spec.ts        # API endpoint tests
```

### Running Specific Tests

```bash
# Single file
npx playwright test tests/example.spec.ts

# Specific browser
npx playwright test --project=chromium

# Match pattern
npx playwright test --grep "API"
```

### Available Browsers

- Chromium (Chrome/Edge)
- Firefox
- WebKit (Safari)
- Mobile Chrome (Pixel 5)
- Mobile Safari (iPhone 12)

For detailed documentation, configuration options, and best practices, see [PLAYWRIGHT_SETUP.md](../docs/PLAYWRIGHT_SETUP.md).
