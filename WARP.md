# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

MetaState Prototype is a monorepo built with TurboRepo and pnpm, implementing a distributed identity and data storage system. The project consists of several core components:

- **W3ID**: Web 3 Identity System for persistent, globally unique identifiers
- **eVault Core**: Secure, distributed data storage with GraphQL API and Neo4j backend
- **eID Wallet**: Tauri-based desktop application for identity management
- **Control Panel**: SvelteKit-based web interface for system monitoring
- **Web3 Adapter**: Service for blockchain integration and mapping

## Build System & Commands

### Monorepo Commands (from root)
```bash
pnpm build          # Build all packages
pnpm dev            # Start development mode for all packages
pnpm test           # Run tests across all packages
pnpm lint           # Lint all packages
pnpm check-lint     # Check linting without fixing
pnpm format         # Format code with Biome
pnpm check-format   # Check formatting without fixing
pnpm check          # Run full check (format, lint, types)
pnpm check-types    # TypeScript type checking
```

### Package-specific Commands
```bash
# Run command in specific package
pnpm -F=w3id test                    # Test W3ID package
pnpm -F=evault-core dev              # Development mode for eVault Core
pnpm -F=eid-wallet storybook         # Start Storybook for eID Wallet
pnpm -F=control-panel dev            # Start Control Panel dev server

# eVault Core specific
cd infrastructure/evault-core
pnpm dev            # Node with watch mode using tsx
pnpm start          # Production start
pnpm build          # TypeScript compilation

# W3ID specific  
cd infrastructure/w3id
pnpm build          # Builds both Node.js and browser versions
pnpm build:node     # Node.js build only
pnpm build:browser  # Browser build only
pnpm dev            # TypeScript watch mode

# eID Wallet (Tauri app)
cd infrastructure/eid-wallet
pnpm tauri dev      # Start Tauri development
pnpm tauri build    # Build Tauri application
pnpm storybook      # Component development
```

### Docker Development
```bash
# eVault with Neo4j database
pnpm dev:evault     # Starts evault.docker-compose.yml with --watch
```

### Testing
```bash
# Run tests for specific components
pnpm -F=w3id test           # W3ID unit tests
pnpm -F=evault-core test    # eVault Core tests with Vitest
```

## Architecture Overview

### Core Identity System (W3ID)
- **Purpose**: Provides persistent, globally unique identifiers using UUID v4/v5
- **Format**: `@<UUID>` for global IDs, `@<UUID>/<UUID>` for local IDs
- **Features**: Key rotation, friend-based recovery, JWT signing, immutable event logging
- **Storage**: Pluggable storage backend through StorageSpec interface

### Data Storage (eVault Core)
- **Database**: Neo4j for graph-based data storage
- **API**: GraphQL endpoint with Fastify HTTP server
- **Access Control**: W3ID-based authentication with ACL
- **Data Model**: MetaEnvelopes containing Envelopes with ontology-based structure
- **Endpoints**: `/graphql`, `/voyager` (schema visualization), `/documentation`

### Applications
- **eID Wallet**: Cross-platform Tauri application built with Svelte
- **Control Panel**: SvelteKit web application with real-time monitoring
- **Platforms**: Firebase-based applications (Blabsy) and other platform integrations

### Development Tools
- **Linting/Formatting**: Biome (configured in biome.json)
- **Type Checking**: TypeScript across all packages
- **Testing**: Vitest for unit/integration tests
- **Storybook**: Component development for UI packages
- **Docker**: Containerized services with compose files

## Environment Setup

### Required Environment Variables (from .env.example)
```bash
# Neo4j Database
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_password

# eVault Configuration
ENCRYPTION_PASSWORD=your_encryption_key
W3ID=your_w3id_identifier
SECRETS_STORE_PATH=/path/to/secrets

# Platform Integration
REGISTRY_URL=http://localhost:4321
EVAULT_BASE_URL=http://localhost:4000
```

### Prerequisites
- Node.js >=18 (specified in package.json engines)
- pnpm (specified as packageManager)
- Neo4j database for eVault Core
- Docker for containerized development

## Key Architectural Patterns

### W3ID Integration
All components authenticate through W3ID system:
1. Obtain W3ID token through authentication
2. Include token in Authorization header for API calls
3. Access resources based on W3ID permissions and ACL

### Workspace Structure
- `infrastructure/`: Core system components (w3id, evault-core, eid-wallet, etc.)
- `platforms/`: Platform-specific integrations (Blabsy, Cerberus)
- `packages/`: Shared configuration (eslint-config, typescript-config)
- `services/`: Utility services (search-engine, web3-adapter)

### Data Flow
1. Platform creates data → Web3 Adapter → eVault Core
2. eVault stores as MetaEnvelopes with ontology classification
3. W3ID provides persistent identity across migrations
4. Control Panel monitors real-time events via Server-Sent Events

### Testing Strategy
- Unit tests with Vitest for core logic
- Integration tests with TestContainers for database components
- Component tests with Storybook for UI elements
- E2E tests with Playwright for full application flows

## Development Workflow

1. **Setup**: `pnpm install` from root to install all dependencies
2. **Development**: Use `pnpm dev` for parallel development or package-specific commands
3. **Testing**: Run tests before commits with `pnpm test`
4. **Code Quality**: Use `pnpm check` to ensure formatting, linting, and type checking
5. **Building**: `pnpm build` creates production builds for all packages
6. **Docker**: Use `pnpm dev:evault` for full eVault development with database

## CI/CD Integration

The project uses GitHub Actions with workflows for:
- **check-code.yml**: Linting, formatting, and type checking on PRs
- **tests-evault-core.yml**: Targeted testing for eVault Core changes
- **tests-w3id.yml**: Targeted testing for W3ID changes

All workflows use Node.js 22 and pnpm for consistent builds.
