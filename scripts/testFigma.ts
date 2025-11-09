#!/usr/bin/env tsx
/*
 * Figma API Connectivity Test
 *
 * Tests connection to Figma REST API and validates configuration.
 * Run from repo root:
 *   - npm run test:figma (from frontend/)
 *   - or from root: cd frontend && npx tsx ../scripts/testFigma.ts
 *
 * Requirements:
 * - FIGMA_API_TOKEN must be set in .env
 * - FIGMA_FILE_KEY is optional
 * - figma-api package must be installed (in frontend/node_modules)
 */

// Note: This script should be run from frontend/ directory to access node_modules
// The npm script "test:figma" handles this automatically

import * as path from 'path';
import * as fs from 'fs';

// ============================================================================
// Color helpers for terminal output
// ============================================================================

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function success(msg: string) {
  console.log(`${colors.green}✅ ${msg}${colors.reset}`);
}

function error(msg: string) {
  console.error(`${colors.red}❌ ${msg}${colors.reset}`);
}

function info(msg: string) {
  console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`);
}

function warning(msg: string) {
  console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`);
}

function section(msg: string) {
  console.log(`\n${colors.bright}${colors.cyan}${msg}${colors.reset}`);
}

// ============================================================================
// Environment Setup
// ============================================================================

/**
 * Load environment variables from .env file manually
 * Searches in multiple locations to support running from different directories
 */
function loadEnvironment() {
  const possibleEnvPaths = [
    path.resolve(process.cwd(), '.env'), // Current directory
    path.resolve(process.cwd(), '..', '.env'), // Parent directory (if in frontend/)
    path.resolve(__dirname, '..', '.env'), // Repo root from script location
  ];

  let loaded = false;
  for (const envPath of possibleEnvPaths) {
    if (fs.existsSync(envPath)) {
      try {
        const envContent = fs.readFileSync(envPath, 'utf-8');
        const lines = envContent.split('\n');

        for (const line of lines) {
          const trimmed = line.trim();
          if (trimmed && !trimmed.startsWith('#')) {
            const match = trimmed.match(/^([^=]+)=(.*)$/);
            if (match) {
              const key = match[1].trim();
              const value = match[2].trim();
              // Only set if not already in environment
              if (!process.env[key]) {
                process.env[key] = value;
              }
            }
          }
        }

        info(`Loaded environment from: ${envPath}`);
        loaded = true;
        break;
      } catch (err) {
        warning(`Could not read ${envPath}`);
      }
    }
  }

  if (!loaded) {
    warning('No .env file found. Relying on system environment variables.');
  }
}

// ============================================================================
// Test Functions
// ============================================================================

/**
 * Dynamically import figma-api to handle module resolution
 * This uses require because the script runs from a different directory than node_modules
 */
async function getFigmaApi() {
  try {
    // Try to load from frontend/node_modules
    const frontendModulePath = path.resolve(__dirname, '../frontend/node_modules/figma-api');
    const module = require(frontendModulePath);
    return module.Api;
  } catch (importError: any) {
    error('Failed to import figma-api package');
    console.log('\n' + colors.dim + 'To fix this:' + colors.reset);
    console.log('  1. Ensure figma-api is installed: cd frontend && npm install');
    console.log('  2. Run from frontend: cd frontend && npm run test:figma');
    console.log(`  3. Error: ${importError.message}\n`);
    process.exit(1);
  }
}

/**
 * Validate that required environment variables are set
 */
function validateEnvironment(): { token: string; fileKey?: string } {
  section('🔍 Environment Validation');

  const token = process.env.FIGMA_API_TOKEN || process.env.FIGMA_API_KEY;
  const fileKey = process.env.FIGMA_FILE_KEY;

  if (!token) {
    error('FIGMA_API_TOKEN not found in environment');
    console.log('\n' + colors.dim + 'To fix this:' + colors.reset);
    console.log('  1. Generate a token at: https://www.figma.com/developers/api#access-tokens');
    console.log('  2. Add to .env file: FIGMA_API_TOKEN=figd_xxxxx');
    console.log('  3. Ensure required scopes: current_user:read, file_content:read\n');
    process.exit(1);
  }

  success('FIGMA_API_TOKEN found');

  // Validate token format
  if (!token.startsWith('figd_')) {
    warning("Token does not start with 'figd_' - may not be a valid Personal Access Token");
  } else {
    success("Token format looks valid (starts with 'figd_')");
  }

  if (fileKey) {
    success(`FIGMA_FILE_KEY found: ${fileKey}`);
  } else {
    info('FIGMA_FILE_KEY not set (optional)');
  }

  return { token, fileKey };
}

/**
 * Test basic API connectivity by calling getUserMe()
 */
async function testUserInfo(api: any): Promise<void> {
  section('👤 Testing User Info (getUserMe)');

  try {
    const response = await api.getUserMe();
    success('Successfully connected to Figma API');
    console.log(`   User: ${colors.bright}${response.handle || response.email}${colors.reset}`);
    console.log(`   ID: ${response.id}`);
    if (response.email) {
      console.log(`   Email: ${response.email}`);
    }
  } catch (err: any) {
    error('Failed to fetch user info');
    console.error(`   ${err.message}`);
    throw err;
  }
}

/**
 * Test file access if FIGMA_FILE_KEY is provided
 */
async function testFileAccess(api: any, fileKey: string): Promise<void> {
  section(`📄 Testing File Access (${fileKey})`);

  try {
    const response = await api.getFile({ file_key: fileKey });
    success('Successfully fetched file');
    console.log(`   Name: ${colors.bright}${response.name}${colors.reset}`);
    console.log(`   Last Modified: ${response.lastModified}`);
    console.log(`   Version: ${response.version}`);

    // Count nodes
    if (response.document?.children) {
      const pageCount = response.document.children.length;
      console.log(`   Pages: ${pageCount}`);
    }

    // Show components if available
    if (response.components && Object.keys(response.components).length > 0) {
      const componentCount = Object.keys(response.components).length;
      console.log(`   Components: ${componentCount}`);
    }
  } catch (err: any) {
    error('Failed to fetch file');
    console.error(`   ${err.message}`);

    if (err.message.includes('404')) {
      console.log(
        '\n' +
          colors.dim +
          'Troubleshooting:' +
          colors.reset +
          '\n' +
          '  • Verify the file key is correct\n' +
          '  • Ensure you have access to the file\n' +
          "  • Check that the file hasn't been deleted\n"
      );
    } else if (err.message.includes('403')) {
      console.log(
        '\n' +
          colors.dim +
          'Troubleshooting:' +
          colors.reset +
          '\n' +
          "  • Verify your token has 'file_content:read' scope\n" +
          '  • Ensure you have permission to access this file\n'
      );
    }

    throw err;
  }
}

/**
 * Display rate limit information and free-tier guidance
 */
function displayRateLimitInfo(): void {
  section('📊 Rate Limit Information');

  console.log(
    `${colors.dim}Figma Free Tier Limits:${colors.reset}\n` +
      `  • 60 requests per minute\n` +
      `  • Rate limits are per-token, not per-file\n` +
      `  • Image URLs expire after ~30 days\n\n` +
      `${colors.dim}This integration includes:${colors.reset}\n` +
      `  • In-memory LRU cache (50 items, 30-min TTL)\n` +
      `  • Automatic cache hit/miss tracking\n` +
      `  • Development mode logging for diagnostics\n\n` +
      `${colors.dim}To avoid rate limits:${colors.reset}\n` +
      `  • Batch requests when possible\n` +
      `  • Use caching (enabled by default)\n` +
      `  • Avoid polling - use webhooks for updates\n`
  );
}

/**
 * Display cache statistics (if service is imported)
 */
function displayCacheInfo(): void {
  section('💾 Cache Configuration');

  console.log(
    `  Max Size: 50 items\n` +
      `  TTL: 30 minutes\n` +
      `  Eviction: LRU (Least Recently Used)\n` +
      `  Scope: In-memory (single process)\n`
  );

  info('Cache stats are available via getCacheStats() in figmaService.ts during runtime');
}

// ============================================================================
// Main Execution
// ============================================================================

async function main() {
  console.log(
    `\n${colors.bright}${colors.cyan}╔════════════════════════════════════════╗${colors.reset}`
  );
  console.log(
    `${colors.bright}${colors.cyan}║   Figma API Connectivity Test         ║${colors.reset}`
  );
  console.log(
    `${colors.bright}${colors.cyan}╚════════════════════════════════════════╝${colors.reset}\n`
  );

  try {
    // Load environment
    loadEnvironment();

    // Validate configuration
    const { token, fileKey } = validateEnvironment();

    // Dynamically load Figma API
    const Api = await getFigmaApi();

    // Initialize Figma API client
    const api = new Api({ personalAccessToken: token });

    // Test user info (always)
    await testUserInfo(api);

    // Test file access (if file key provided)
    if (fileKey) {
      await testFileAccess(api, fileKey);
    } else {
      info(
        '\nSkipping file access test (FIGMA_FILE_KEY not set)\n' +
          'To test file access, add FIGMA_FILE_KEY to your .env file'
      );
    }

    // Display informational sections
    displayRateLimitInfo();
    displayCacheInfo();

    // Success summary
    console.log(
      `\n${colors.green}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`
    );
    success('All tests passed! Figma integration is ready to use.');
    console.log(
      `${colors.green}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`
    );

    process.exit(0);
  } catch (err: any) {
    console.log(
      `\n${colors.red}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`
    );
    error('Test failed');
    console.log(
      `${colors.red}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`
    );

    // Show detailed error information
    console.error(`${colors.red}Error: ${err.message}${colors.reset}\n`);

    if (err.response) {
      console.error(
        `${colors.dim}HTTP ${err.response.status}: ${err.response.statusText}${colors.reset}`
      );
      if (err.response.data) {
        console.error(`${colors.dim}Response:`, err.response.data, `${colors.reset}`);
      }
    }

    if (err.stack && process.env.DEBUG) {
      console.error(`\n${colors.dim}Stack trace:${colors.reset}`);
      console.error(err.stack);
    }

    process.exit(1);
  }
}

// Run the test
main();
