<!--
  ============================================================================
  SYNC IMPACT REPORT - Constitution Update to v1.1.0
  ============================================================================

  VERSION CHANGE: 1.0.0 → 1.1.0 (Pre-commit Hook Enforcement)

  MODIFIED PRINCIPLES:
  - EXPANDED: V. Developer Experience and Automation - Strengthened pre-commit hook requirements
    * Made pre-commit hooks mandatory (not optional)
    * Emphasized continuous enforcement throughout development
    * Added explicit prohibition against bypassing hooks

  ADDED SECTIONS:
  - None

  REMOVED SECTIONS:
  - None

  TEMPLATE UPDATES:
  ✅ .specify/templates/plan-template.md - Verified Constitution Check alignment
  ✅ .specify/templates/spec-template.md - Verified alignment (no changes needed)
  ✅ .specify/templates/tasks-template.md - Verified alignment (no changes needed)
  ✅ .specify/templates/agent-file-template.md - Verified alignment (no changes needed)
  ✅ .specify/templates/checklist-template.md - Verified alignment (no changes needed)

  FOLLOW-UP TODOS:
  - None (all placeholders filled, all templates aligned)

  RATIONALE FOR VERSION BUMP:
  - MINOR bump (1.1.0) for material expansion of Principle V guidance
  - Pre-commit hooks elevated from automation practice to mandatory requirement
  - Updated LAST_AMENDED_DATE to 2025-11-07 (current date)
  - Confirmed all principles remain relevant to current project phase
  - Verified technology standards match current stack:
    * Node.js 24 LTS ✓
    * Next.js 16 ✓ (updated from 15)
    * TypeScript 5.6+ ✓
    * React 19 ✓ (updated from 18)
    * MSAL for Entra ID ✓
    * Azure SDK (@azure/identity, @azure/keyvault-secrets) ✓
    * Bicep for IaC ✓
    * ESLint 9, Prettier 3, Commitlint ✓
  - All examples remain accurate and reflect actual codebase patterns
  - No violations or deferred items detected

  VALIDATION FINDINGS:
  - Constitution principles actively enforced through pre-commit hooks
  - Dev Container configuration aligns with Principle V
  - Infrastructure as Code fully implemented in Bicep templates
  - Type safety enforced (TypeScript strict mode enabled)
  - Security patterns followed (Entra ID, Key Vault, Managed Identity)
  - Documentation up-to-date with current architecture

  ============================================================================
-->

# TS Azure Health Constitution

## Core Principles

### I. Cloud-Native Azure Integration

All components must be designed for Azure cloud services with proper authentication, security, and observability. The application leverages Azure-managed services (Container Apps, Key Vault, Entra ID) rather than self-managed infrastructure.

**Rationale**: Enterprise applications require robust security, scalability, and compliance. Azure-native patterns ensure we benefit from Microsoft's security investments, managed identity systems, and compliance certifications while reducing operational overhead.

**Examples**:

- ✅ Use Managed Identity for Azure resource access instead of connection strings
- ✅ Store secrets in Azure Key Vault with proper RBAC instead of environment variables
- ❌ Hardcode connection strings or API keys in configuration files
- ❌ Build custom authentication when Entra ID provides enterprise-grade auth

### II. Type Safety First

TypeScript strict mode must be enforced across all code. No `any` types without explicit justification. All data models, API contracts, and configurations must have proper type definitions.

**Rationale**: Type safety prevents runtime errors, improves developer productivity through IntelliSense, and serves as living documentation. In enterprise applications handling sensitive data, compile-time guarantees reduce production incidents.

**Examples**:

- ✅ Define interfaces for API responses and use them consistently
- ✅ Enable `strict: true` and `noEmit: true` in TypeScript configuration
- ❌ Use `any` type to bypass compiler errors
- ❌ Skip type checking with `@ts-ignore` without documented justification

### III. Security by Default

Authentication and authorization must be enforced at every layer. Entra ID integration is mandatory for user authentication, with proper token validation. Secrets must never be committed to source control.

**Rationale**: Healthcare and enterprise applications must protect sensitive data and comply with regulations. Security cannot be retrofitted; it must be built into the foundation through proper authentication flows, token handling, and secret management.

**Examples**:

- ✅ Implement On-Behalf-Of (OBO) flow for backend API calls
- ✅ Validate access tokens on every API endpoint using MSAL
- ❌ Disable authentication "temporarily" for development convenience
- ❌ Store Azure credentials or tokens in .env files committed to Git

### IV. Infrastructure as Code

All Azure resources must be defined in Bicep templates with proper parameterization, versioning, and validation. Manual Azure portal changes are prohibited for production resources.

**Rationale**: Infrastructure as Code ensures reproducibility, enables disaster recovery, facilitates testing in isolated environments, and provides audit trails. Manual changes lead to configuration drift and make scaling impossible.

**Examples**:

- ✅ Define Container Apps, Key Vault, and Managed Identities in main.bicep
- ✅ Use Bicep linting and validation in CI/CD pipelines
- ❌ Create Azure resources manually through Azure Portal for production
- ❌ Skip Bicep parameter files and hardcode environment-specific values

### V. Developer Experience and Automation

Development environments must be reproducible via Dev Containers. Code quality is enforced through mandatory pre-commit hooks that run automated linting, formatting, type checking, and validation on every commit. Pre-commit hooks are NOT optional and must never be bypassed. Manual setup steps are anti-patterns.

**Rationale**: Inconsistent development environments cause "works on my machine" problems. Pre-commit hooks provide the earliest possible failure point, catching errors before they enter the repository. This reduces CI/CD failures, prevents broken builds, improves code review efficiency, and ensures consistent quality standards across all team members. Automation reduces cognitive load and enables faster onboarding.

**Pre-commit Hook Requirements**:

- MUST be installed and configured in every development environment
- MUST run on every commit without exception
- MUST include: code linting (ESLint), formatting (Prettier), type checking (TypeScript), file quality checks
- MUST fail the commit if any check fails
- MUST be configured via Husky in `frontend/.husky/` (git hooks managed by Husky scripts)
  - If additional file validation is performed via `.pre-commit-config.yaml`, this must be documented and maintained, but Husky is the required framework for git hooks.

**Examples**:

- ✅ Install pre-commit hooks automatically in Dev Container setup
- ✅ Run ESLint, Prettier, TypeScript, and file checks via pre-commit framework
- ✅ Fail commits that violate linting, formatting, or type checking rules
- ✅ Document pre-commit installation in README and development setup guides
- ❌ Allow commits without pre-commit hooks installed
- ❌ Use `--no-verify` flag to skip pre-commit checks (requires CONSTITUTION EXCEPTION comment)
- ❌ Disable or comment out pre-commit checks "temporarily"
- ❌ Require developers to manually run linting/formatting before commits

## Technology Standards

**Mandatory Stack**:

- Runtime: Node.js 24 LTS
- Framework: Next.js 16 with App Router
- Language: TypeScript 5.6+ with strict mode
- UI Library: React 19
- Authentication: MSAL (Microsoft Authentication Library) for Entra ID
- Azure SDK: @azure/identity and @azure/keyvault-secrets for Azure resource access
- Infrastructure: Bicep for Azure resource definitions
- Code Quality: ESLint 9, Prettier 3, Commitlint for conventional commits
- Pre-commit Framework: pre-commit with hooks for linting, formatting, type checking, and file validation

**Forbidden Patterns**:

- No JavaScript files in src/ directories (TypeScript only)
- No `any` types without JSDoc justification comment
- No secrets in environment variables (use Key Vault)
- No manual Azure resource creation for production
- No commits without pre-commit hooks installed and running
- No use of `git commit --no-verify` or `SKIP=` environment variable to bypass pre-commit hooks (requires CONSTITUTION EXCEPTION in commit message if absolutely necessary)
- No disabling or removing pre-commit hook configurations without architectural review

**CLI Command Standards**:

- All terminal commands executed by AI assistants MUST prevent interactive pagers
- Use `| cat` suffix for commands that may trigger pagers (git, gh, less, more)
- Use `--no-pager` flag when available (e.g., `git --no-pager`, `gh --no-pager`)
- Use output limiters (`head`, `tail`, `grep`) to prevent excessive output
- Never leave commands in pager mode requiring manual `q` to exit
- Examples:
  - ✅ `gh secret list | cat`
  - ✅ `git --no-pager log --oneline -10`
  - ✅ `az group list --output table | head -20`
  - ❌ `gh secret list` (may trigger pager)
  - ❌ `git log` (will trigger pager for long output)

## Architectural Constraints

**Complexity Limits**:

- Maximum of 2 primary layers (frontend + infrastructure). No backend service layer unless explicitly required.
- Minimize third-party packages. Prefer Azure SDK and Next.js built-ins over abstractions.
- Maximum 3 layers of abstraction (e.g., Page → Service → Azure SDK)
- TypeScript files should not exceed 300 lines. Extract modules when approaching this limit.

**Design Patterns**:

- Prefer: Direct Azure SDK usage, Next.js API routes for BFF pattern, React Server Components
- Avoid: Overly abstracted service layers, custom auth implementations, client-side secret management
- Required: Separation of concerns (UI components, API routes, Azure integration utilities)

## Governance

**Amendment Process**:

1. Propose constitutional changes via pull request to `.specify/memory/constitution.md`
2. Include rationale and impact analysis in PR description
3. Require approval from 2+ project maintainers
4. Update version (major for principle changes, minor for clarifications)
5. Document change in version history HTML comment

**Violation Handling**:

- Automated Enforcement: Pre-commit hooks MUST be installed and MUST pass on every commit. TypeScript compiler, Bicep linter, ESLint must pass.
- Pre-commit Verification: If a commit bypasses hooks (--no-verify), it MUST include "CONSTITUTION EXCEPTION" in the commit message with justification
- Code Review: Reviewers must verify alignment with principles before approval and check for hook bypasses
- Justified Exceptions: Document in code comments with pattern: `// CONSTITUTION EXCEPTION: [Principle Name] - [Justification]`
- Technical Debt: Track constitutional violations as GitHub issues with `tech-debt` label

**Periodic Review**:

- Review constitution quarterly or when major technology shifts occur
- Ensure principles remain relevant to current project phase and team size
- Update examples to reflect actual codebase patterns

**Version**: 1.1.0 | **Ratified**: 2025-01-06 | **Last Amended**: 2025-11-07
