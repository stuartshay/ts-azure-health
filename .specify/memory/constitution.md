<!--
  ============================================================================
  SYNC IMPACT REPORT - Constitution Update to v1.0.0
  ============================================================================
  
  VERSION CHANGE: None → 1.0.0 (Initial Ratification)
  
  MODIFIED PRINCIPLES:
  - NEW: I. Cloud-Native Azure Integration
  - NEW: II. Type Safety First
  - NEW: III. Security by Default
  - NEW: IV. Infrastructure as Code
  - NEW: V. Developer Experience and Automation
  
  ADDED SECTIONS:
  - Technology Standards (mandatory stack, forbidden patterns)
  - Architectural Constraints (complexity limits, design patterns)
  - Governance (amendment process, violation handling, periodic review)
  
  REMOVED SECTIONS:
  - None (initial constitution)
  
  TEMPLATE UPDATES:
  ✅ .specify/templates/plan-template.md - Updated Constitution Check gates
  ✅ .specify/templates/spec-template.md - No changes required (already aligned)
  ✅ .specify/templates/tasks-template.md - No changes required (already aligned)
  ✅ .specify/templates/agent-file-template.md - No changes required
  ✅ .specify/templates/checklist-template.md - No changes required
  
  FOLLOW-UP TODOS:
  - None (all placeholders filled)
  
  RATIONALE FOR VERSION BUMP:
  - 1.0.0 chosen as initial ratification version
  - Principles derived from project README, package.json, infrastructure, and devcontainer configuration
  - All 5 principles directly reflect current project practices and technology choices
  
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

Development environments must be reproducible via Dev Containers. Code quality is enforced through automated linting, formatting, type checking, and pre-commit hooks. Manual setup steps are anti-patterns.

**Rationale**: Inconsistent development environments cause "works on my machine" problems. Automation reduces cognitive load, catches errors early, and ensures consistent code quality across team members, enabling faster onboarding and reducing review burden.

**Examples**:
- ✅ Provide complete Dev Container configuration with all tools pre-installed
- ✅ Run ESLint, Prettier, and TypeScript checks automatically via husky hooks
- ❌ Require developers to manually install Node.js, Azure CLI, or extensions
- ❌ Skip linting rules or disable pre-commit hooks to speed up commits

## Technology Standards

**Mandatory Stack**:
- Runtime: Node.js 22 LTS
- Framework: Next.js 15 with App Router
- Language: TypeScript 5.6+ with strict mode
- Authentication: MSAL (Microsoft Authentication Library) for Entra ID
- Azure SDK: @azure/identity and @azure/keyvault-secrets for Azure resource access
- Infrastructure: Bicep for Azure resource definitions
- Code Quality: ESLint 9, Prettier 3, Commitlint for conventional commits

**Forbidden Patterns**:
- No JavaScript files in src/ directories (TypeScript only)
- No `any` types without JSDoc justification comment
- No secrets in environment variables (use Key Vault)
- No manual Azure resource creation for production
- No commits bypassing pre-commit hooks without documented reason

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
- Automated Enforcement: Pre-commit hooks, TypeScript compiler, Bicep linter, ESLint must pass
- Code Review: Reviewers must verify alignment with principles before approval
- Justified Exceptions: Document in code comments with pattern: `// CONSTITUTION EXCEPTION: [Principle Name] - [Justification]`
- Technical Debt: Track constitutional violations as GitHub issues with `tech-debt` label

**Periodic Review**:
- Review constitution quarterly or when major technology shifts occur
- Ensure principles remain relevant to current project phase and team size
- Update examples to reflect actual codebase patterns

**Version**: 1.0.0 | **Ratified**: 2025-01-06 | **Last Amended**: 2025-01-06
