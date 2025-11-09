# Essential Development Tools & Recommended Setup

This document outlines recommended tools and practices to enhance the development workflow for ts-azure-health.

## Table of Contents

- [Testing & Quality Assurance](#testing--quality-assurance)
- [CI/CD Enhancements](#cicd-enhancements)
- [Monitoring & Observability](#monitoring--observability)
- [Documentation Tools](#documentation-tools)
- [Development Environment](#development-environment)
- [Security & Compliance](#security--compliance)
- [Figma-Specific Tools](#figma-specific-tools)
- [Quick Wins](#quick-wins)

---

## Testing & Quality Assurance

### Unit & Integration Testing

**Recommended: Vitest** (faster than Jest, better Next.js support)

```bash
npm install --save-dev vitest @vitest/ui @testing-library/react @testing-library/jest-dom
```

**Benefits:**

- Native ES modules support
- Faster test execution
- Better TypeScript integration
- Compatible with existing Jest tests

**Configuration:** Create `vitest.config.ts`

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'test/', '.next/'],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './'),
    },
  },
});
```

**Priority Tests:**

1. `lib/figmaService.ts` - Cache logic, API client
2. `lib/msalClient.ts` - Authentication flows
3. API routes - `/api/figma/preview`, `/api/call-downstream`

### End-to-End Testing

**Recommended: Playwright** (already installed in devcontainer)

```bash
npm install --save-dev @playwright/test
npx playwright install
```

**Test Scenarios:**

- User authentication flow (MSAL)
- Figma preview API integration
- Key Vault secret retrieval
- Downstream API calls

### Visual Regression Testing

**Recommended: Chromatic or Percy**

For Figma integration visual consistency:

- Detect unintended UI changes
- Compare design assets from Figma
- Track component library changes

---

## CI/CD Enhancements

### GitHub Actions Improvements

#### 1. Automated PR Labeling

Create `.github/labeler.yml`:

```yaml
'area: infrastructure':
  - infrastructure/**/*
  - scripts/infrastructure/**/*

'area: frontend':
  - frontend/**/*

'area: figma':
  - '**/figma*'
  - docs/copilot_figma_setup.md

'type: security':
  - '**/auth*'
  - '**/msal*'
  - '**/*security*'
```

#### 2. Dependency Management

**Enable Dependabot:** Create `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: 'npm'
    directory: '/frontend'
    schedule:
      interval: 'weekly'
    open-pull-requests-limit: 10
    groups:
      azure:
        patterns:
          - '@azure/*'
      development:
        patterns:
          - '@types/*'
          - 'eslint*'
          - 'prettier'

  - package-ecosystem: 'docker'
    directory: '/frontend'
    schedule:
      interval: 'weekly'

  - package-ecosystem: 'github-actions'
    directory: '/'
    schedule:
      interval: 'monthly'
```

#### 3. Code Coverage Reporting

Add to GitHub Actions workflow:

```yaml
- name: Run tests with coverage
  run: npm run test:coverage

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    file: ./coverage/coverage-final.json
    fail_ci_if_error: true
```

#### 4. Bundle Size Monitoring

```bash
npm install --save-dev @next/bundle-analyzer
```

Add to `next.config.ts`:

```typescript
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer(nextConfig);
```

---

## Monitoring & Observability

### Application Insights (Azure)

**Already using Azure - integrate Application Insights:**

```bash
npm install @microsoft/applicationinsights-web
```

**Track:**

- Figma API rate limit metrics
- Cache hit/miss ratios
- Authentication failures
- API response times

### Error Tracking

**Recommended: Sentry**

```bash
npm install @sentry/nextjs
```

**Setup:** `sentry.client.config.js`

```javascript
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  beforeSend(event) {
    // Filter out PII
    if (event.request) {
      delete event.request.cookies;
    }
    return event;
  },
});
```

### Figma API Monitoring

Create dashboard to track:

- Rate limit consumption (60 req/min)
- Cache effectiveness (hit/miss ratio)
- Image CDN URL expiration patterns
- API error rates by endpoint

---

## Documentation Tools

### API Documentation

**Recommended: Swagger/OpenAPI for Next.js API Routes**

```bash
npm install --save-dev next-swagger-doc swagger-ui-react
```

**Document:**

- `/api/figma/preview` - Query params, responses
- `/api/call-downstream` - Auth requirements
- `/api/kv-secret` - Security considerations

### Component Library

**Recommended: Storybook**

```bash
npx storybook@latest init
```

**Benefits:**

- Document React components
- Showcase Figma-integrated components
- Visual testing playground
- Design system documentation

### Architecture Decision Records (ADRs)

Create `docs/adr/` directory:

```
docs/
└── adr/
    ├── 0001-use-next-js-app-router.md
    ├── 0002-figma-rest-api-integration.md
    ├── 0003-server-side-only-figma-token.md
    └── template.md
```

**Template:**

```markdown
# [Number]. [Title]

Date: YYYY-MM-DD

## Status

[Proposed | Accepted | Deprecated | Superseded]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?
```

---

## Development Environment

### VS Code Configuration

#### Recommended Extensions (`.vscode/extensions.json`)

```json
{
  "recommendations": [
    "ms-azuretools.vscode-azureappservice",
    "ms-azuretools.vscode-azurefunctions",
    "ms-azuretools.vscode-bicep",
    "figma.figma-vscode-extension",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-playwright.playwright",
    "vitest.explorer",
    "bradlc.vscode-tailwindcss",
    "streetsidesoftware.code-spell-checker",
    "eamodio.gitlens"
  ]
}
```

#### Workspace Settings (`.vscode/settings.json`)

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "typescript.tsdk": "frontend/node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "files.exclude": {
    "**/.next": true,
    "**/node_modules": true
  },
  "search.exclude": {
    "**/.next": true,
    "**/node_modules": true,
    "**/package-lock.json": true
  }
}
```

#### Debug Configuration (`.vscode/launch.json`)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug server-side",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev",
      "cwd": "${workspaceFolder}/frontend",
      "serverReadyAction": {
        "pattern": "- Local:.+(https?://.+)",
        "uriFormat": "%s",
        "action": "debugWithChrome"
      }
    },
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000"
    },
    {
      "name": "Next.js: debug full stack",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev",
      "cwd": "${workspaceFolder}/frontend",
      "console": "integratedTerminal",
      "serverReadyAction": {
        "pattern": "- Local:.+(https?://.+)",
        "uriFormat": "%s",
        "action": "debugWithChrome"
      }
    },
    {
      "type": "node-terminal",
      "name": "Run Figma Test Script",
      "request": "launch",
      "command": "npm run test:figma",
      "cwd": "${workspaceFolder}/frontend"
    }
  ]
}
```

---

## Security & Compliance

### Secret Scanning

**GitHub Secret Scanning** - Ensure enabled:

- Repository Settings → Security → Secret scanning

**Additional tool: TruffleHog**

```bash
# Pre-commit hook
docker run --rm -v "$(pwd)":/workdir trufflesecurity/trufflehog:latest git file:///workdir
```

### Dependency Vulnerability Scanning

**npm audit in CI:**

```yaml
- name: Security audit
  run: |
    npm audit --audit-level=moderate
    npm audit --production --audit-level=high
```

**Snyk Integration:**

```bash
npm install -g snyk
snyk test
snyk monitor
```

### Container Security

**Scan Docker images:**

```bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ts-azure-health-frontend:latest
```

**Add to CI workflow:**

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'ts-azure-health-frontend:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### OWASP Dependency-Check

```bash
npm install --save-dev @owasp/dependency-check
```

Add to package.json:

```json
{
  "scripts": {
    "security:check": "dependency-check --project ts-azure-health --scan ./frontend"
  }
}
```

---

## Figma-Specific Tools

### Webhook Integration

**Setup Figma webhooks for design updates:**

1. **Create webhook endpoint:** `/api/figma/webhook`
2. **Handle events:**
   - `FILE_UPDATE` - Design changed
   - `FILE_VERSION_UPDATE` - New version
   - `FILE_DELETE` - File removed

```typescript
// frontend/app/api/figma/webhook/route.ts
export async function POST(request: NextRequest) {
  const signature = request.headers.get('X-Figma-Signature');
  const body = await request.text();

  // Verify webhook signature
  // Process event
  // Invalidate cache if needed
  // Notify team via Slack/Teams
}
```

### Design Tokens Sync

**Style Dictionary for design system tokens:**

```bash
npm install --save-dev style-dictionary
```

**Sync workflow:**

1. Extract tokens from Figma
2. Transform to CSS variables
3. Generate TypeScript types
4. Commit to repo

### Visual Regression Testing

**Chromatic (for Storybook):**

```bash
npm install --save-dev chromatic
```

**Percy (for full-page screenshots):**

```bash
npm install --save-dev @percy/cli @percy/playwright
```

**Test scenarios:**

- Figma preview component rendering
- Design token applications
- Responsive layouts from Figma frames

---

## Quick Wins

### Immediate Actions (1-2 days)

1. **Add Vitest with basic tests**

   ```bash
   cd frontend
   npm install --save-dev vitest @testing-library/react @testing-library/jest-dom
   ```

   - Write tests for `figmaService.ts` cache logic
   - Test API route error handling

2. **Enable Dependabot**

   - Create `.github/dependabot.yml`
   - Group Azure packages
   - Weekly schedule

3. **Add VS Code workspace settings**

   - Create `.vscode/` folder
   - Add `settings.json` and `extensions.json`
   - Document debug configurations

4. **Setup Code Coverage**
   - Add coverage scripts to package.json
   - Integrate Codecov in GitHub Actions
   - Set minimum coverage threshold (70%)

### Medium-term (1-2 weeks)

5. **Application Insights Integration**

   - Add to Next.js app
   - Track Figma API metrics
   - Monitor cache performance

6. **Storybook Setup**

   - Initialize Storybook
   - Document existing components
   - Add Figma plugin for design comparison

7. **E2E Testing with Playwright**

   - Write critical path tests
   - Add to CI pipeline
   - Generate test reports

8. **Security Scanning**
   - Enable GitHub Advanced Security
   - Add Snyk or Trivy
   - Create security policy

### Long-term (1 month+)

9. **Figma Webhooks**

   - Implement webhook endpoint
   - Cache invalidation strategy
   - Team notifications

10. **Design System Documentation**

    - ADRs for architecture decisions
    - API documentation with Swagger
    - Component library with Storybook

11. **Performance Monitoring**

    - Bundle size tracking
    - Lighthouse CI integration
    - Performance budgets

12. **Advanced Testing**
    - Visual regression with Percy/Chromatic
    - Load testing for API routes
    - Chaos engineering for resilience

---

## Implementation Priority

### Must Have (Critical)

- ✅ Vitest + basic tests
- ✅ Dependabot
- ✅ Code coverage tracking
- ✅ Security scanning (npm audit + Snyk)

### Should Have (Important)

- ⚠️ Application Insights
- ⚠️ VS Code workspace configuration
- ⚠️ E2E tests with Playwright
- ⚠️ API documentation

### Nice to Have (Optional)

- 💡 Storybook
- 💡 Visual regression testing
- 💡 Figma webhooks
- 💡 Advanced monitoring dashboards

---

## Resource Links

### Testing

- [Vitest Documentation](https://vitest.dev/)
- [Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [Playwright Documentation](https://playwright.dev/)

### Monitoring

- [Azure Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Sentry Next.js](https://docs.sentry.io/platforms/javascript/guides/nextjs/)

### Documentation

- [Storybook](https://storybook.js.org/)
- [ADR Tools](https://adr.github.io/)
- [Swagger/OpenAPI](https://swagger.io/docs/)

### Security

- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [Snyk](https://docs.snyk.io/)
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)

### Figma

- [Figma Webhooks](https://www.figma.com/developers/api#webhooks)
- [Style Dictionary](https://amzn.github.io/style-dictionary/)
- [Figma Plugin API](https://www.figma.com/plugin-docs/)

---

## Questions & Support

For questions about implementing these tools:

1. Check the linked documentation
2. Review existing GitHub Actions workflows
3. Consult with the development team
4. Create an issue in the repository

**Last Updated:** November 9, 2025
