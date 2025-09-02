# MetaState Prototype - Architecture Documentation

This directory contains architecture diagrams following the C4 model (Context, Container, Component, and Class diagrams) for the MetaState Prototype Project.

## Architecture Diagrams

### 1. System Context Diagram
**File:** [diagrams/01-context-diagram.md](diagrams/01-context-diagram.md)

Shows the high-level view of the MetaState Prototype system in its environment, including:
- External users (End Users, Developers, System Administrators)
- External systems (Neo4j Database, Registry Service, Blockchain Networks, Platform Applications)
- The MetaState Prototype system as a single entity

### 2. Container Diagram
**File:** [diagrams/02-container-diagram.md](diagrams/02-container-diagram.md)

Zooms into the MetaState system to show the major containers (applications and databases):
- **W3ID**: TypeScript-based identity management system
- **eVault Core**: Node.js/Fastify GraphQL API for secure data storage
- **eID Wallet**: Tauri/Svelte cross-platform desktop application
- **Control Panel**: SvelteKit web dashboard for system monitoring
- **Web3 Adapter**: TypeScript service for blockchain integration
- **Search Engine**: Node.js/Express unified search service

### 3. Component Diagram - eVault Core
**File:** [diagrams/03-component-diagram-evault.md](diagrams/03-component-diagram-evault.md)

Detailed view of the eVault Core container showing its internal components:
- **GraphQL Server**: Yoga GraphQL server with schema and resolvers
- **HTTP Server**: Fastify server with REST endpoints and documentation
- **Vault Access Guard**: JWT validation and ACL enforcement
- **Database Service**: Neo4j operations for MetaEnvelopes and Envelopes
- **W3ID Integration**: W3ID instance management and JWT signing
- **Log Service**: W3ID event logging with immutable log chains
- **Schema Management**: Data serialization/deserialization
- **Webhook Service**: Platform notification system
- **Secrets Store**: Encrypted file-based secret management

### 4. Component Diagram - W3ID
**File:** [diagrams/05-component-diagram-w3id.md](diagrams/05-component-diagram-w3id.md)

Detailed view of the W3ID container showing its internal components for identity management:
- **W3ID**: Main identity class providing JWT signing capabilities and identity operations
- **W3IDBuilder**: Builder pattern implementation for creating W3ID instances with various configurations
- **IDLogManager**: Manages immutable event logging, key rotation, and cryptographic validation of log chains
- **StorageSpec Interface**: Generic storage abstraction allowing pluggable storage backends
- **Cryptographic Utils**: JWT signing/verification, SHA256 hashing, UUID generation (v4/v5), and secure random generation
- **Codec Utils**: Data encoding/decoding utilities for consistent data serialization
- **Array Utils**: Set operations for key validation and comparison during log chain validation
- **Error Handling**: Custom error types for validation failures, malformed chains, and signature verification

### 5. Component Diagram - Web3 Adapter
**File:** [diagrams/06-component-diagram-web3-adapter.md](diagrams/06-component-diagram-web3-adapter.md)

Detailed view of the Web3 Adapter container showing its internal components for blockchain and platform integration:
- **Web3 Adapter**: Main orchestrator class managing platform data synchronization with eVaults
- **Mapping Engine**: Transforms platform-specific data to/from universal MetaEnvelope format using configurable field mappings
- **Mapping Database**: SQLite-based persistence layer storing local-to-global ID mappings for data synchronization
- **EVault Client**: GraphQL client interface providing operations for storing, updating, and referencing MetaEnvelopes
- **eVault Provisioner**: Handles creation and configuration of new eVaults through registry and provisioner services
- **Schema Manager**: Manages JSON schema mappings and validation rules for different platform data structures
- **Logger System**: Structured logging infrastructure with configurable transports for audit and debugging

### 6. Class Diagram
**File:** [diagrams/04-class-diagram.md](diagrams/04-class-diagram.md)

Shows the key classes and their relationships in both W3ID and eVault Core systems:

#### W3ID Core Classes:
- **W3ID**: Main identity class with JWT signing capabilities
- **W3IDBuilder**: Builder pattern for creating W3ID instances
- **IDLogManager**: Manages immutable event logging
- **StorageSpec\<T, R\>**: Generic storage interface
- **LogService**: Neo4j implementation of StorageSpec
- **SecretsStore**: Encrypted secret management

#### eVault Core Classes:
- **MetaEnvelope\<T\>**: Data structure with ontology and ACL
- **Envelope\<T\>**: Individual data container with type information
- **DbService**: Neo4j database operations
- **GraphQLServer**: GraphQL server with webhook support
- **VaultAccessGuard**: Authentication and authorization middleware
- **EVaultClient**: Client for eVault operations with health monitoring

#### Supporting Types and Interfaces:
- **Signer**: Cryptographic signing interface
- **LogEvent**: W3ID event log structure
- **VaultContext**: GraphQL context with authentication info

## Key Architectural Patterns

### 1. **W3ID Integration Pattern**
All components authenticate through the W3ID system:
1. Obtain W3ID token through authentication
2. Include token in Authorization header
3. Access resources based on W3ID permissions and ACL

### 2. **MetaEnvelope Data Model**
The eVault uses a hierarchical data structure:
- **MetaEnvelope**: Top-level container with ontology classification
- **Envelope**: Individual data items with type information
- **ACL**: Fine-grained access control per MetaEnvelope

### 3. **Event-Driven Architecture**
- W3ID maintains immutable event logs for identity operations
- eVault sends webhook notifications to platforms on data changes
- Control Panel streams real-time events via Server-Sent Events

### 4. **Microservices Architecture**
- Each container is independently deployable
- Services communicate via HTTP/GraphQL APIs
- Registry service enables dynamic service discovery

### 5. **Storage Strategy**
- Neo4j graph database for complex data relationships
- File-based encrypted storage for secrets
- In-memory caching for performance optimization

## Technology Stack

### Core Technologies:
- **Languages**: TypeScript, Node.js
- **Frameworks**: Fastify, GraphQL Yoga, SvelteKit, Tauri
- **Database**: Neo4j (graph database)
- **Build System**: TurboRepo with pnpm
- **Code Quality**: Biome (linting/formatting), Vitest (testing)

### Key Libraries:
- **Identity**: W3ID with UUID v4/v5, JWT signing with `jose`
- **Cryptography**: TweetNaCl for signing and encryption
- **Testing**: Vitest with TestContainers for integration tests
- **UI Components**: Svelte with Storybook for component development

## Development Workflow

1. **Setup**: `pnpm install` from root installs all dependencies
2. **Development**: Use `pnpm dev` for parallel development
3. **Testing**: `pnpm test` runs tests across all packages
4. **Quality**: `pnpm check` ensures formatting, linting, and types
5. **Building**: `pnpm build` creates production builds

## Environment Requirements

- Node.js ≥18
- pnpm package manager
- Neo4j database for eVault Core
- Docker for containerized development (`pnpm dev:evault`)

## Thoughts and Analysis

This section contains strategic analysis and architectural thoughts about the MetaState Prototype system:

### Strategic Analysis Documents
**File:** [thoughts-on-transforming-to-elixir.md](thoughts-on-transforming-to-elixir.md)

Comprehensive analysis of migrating the MetaState backend services from TypeScript/Node.js to Elixir/Erlang, including:
- Component-by-component value assessment for migration potential
- Detailed migration strategy with 3-phase approach
- Worst-case scenario analysis and risk mitigation strategies
- Performance impact projections and architectural benefits
- Decision framework with go/no-go criteria for each phase
- Recommendation for selective migration approach
