# Working with the MetaState Prototype Codebase

[← Back to Documentation](README.md)

This guide provides step-by-step instructions for getting started with the MetaState Prototype codebase and working with its Docker-based development environment.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Node.js ≥18** - Required for running the TypeScript/JavaScript applications
- **pnpm** - Package manager (specified as `packageManager` in package.json)
- **Docker & Docker Compose** - For containerized development environment
- **Git** - For version control

### Installing Prerequisites

#### Node.js & pnpm
```bash
# Install Node.js (v18 or higher)
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Install pnpm globally
npm install -g pnpm@10.13.1
```

#### Docker
```bash
# On Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# On Arch Linux
sudo pacman -S docker docker-compose

# On macOS (using Homebrew)
brew install docker docker-compose

# Start Docker service (Linux)
sudo systemctl start docker
sudo systemctl enable docker
```

---

## Getting Started

### 1. Clone and Setup the Repository

```bash
# Clone the repository
git clone https://github.com/rgfaber/metastate-prototype.git
cd metastate-prototype

# Install all dependencies across the monorepo
pnpm install
```

### 2. Environment Configuration

Copy the example environment file and configure it for your setup:

```bash
# Create your environment file from the template
cp .env.example .env

# Edit the environment file with your preferred editor
nano .env  # or vim, code, etc.
```

#### Required Environment Variables

Edit your `.env` file with appropriate values:

```bash
# Neo4j Configuration (for eVault Core)
NEO4J_URI=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_secure_password_here

# eVault Configuration
PORT=4000
ENCRYPTION_PASSWORD=your_encryption_key_here
W3ID=your_w3id_identifier

# Platform URLs (optional for basic setup)
PUBLIC_REGISTRY_URL=http://localhost:4321
PUBLIC_PROVISIONER_URL=http://localhost:4322
PUBLIC_PICTIQUE_BASE_URL=your_pictique_url_here
PUBLIC_BLABSY_BASE_URL=your_blabsy_url_here
```

### 3. Initial Build

Build all packages to ensure everything compiles correctly:

```bash
# Build all packages in the monorepo
pnpm build

# Check code quality (formatting, linting, types)
pnpm check
```

---

## Development Workflows

### Running the Full Development Environment

The MetaState Prototype uses Turborepo to orchestrate development across multiple packages:

```bash
# Start all services in development mode
pnpm dev

# This will concurrently run:
# - W3ID library compilation (watch mode)
# - eVault Core API server
# - Control Panel web interface
# - eID Wallet application
# - Other infrastructure services
```

### Working with Individual Packages

You can also work with individual packages using pnpm's workspace filtering:

```bash
# Work with specific packages
pnpm -F=w3id dev                    # W3ID library development
pnpm -F=evault-core dev             # eVault Core API development
pnpm -F=eid-wallet dev              # eID Wallet application
pnpm -F=control-panel dev           # Control Panel web interface
pnpm -F=web3-adapter dev            # Web3 Adapter service

# Run tests for specific packages
pnpm -F=w3id test                   # W3ID unit tests
pnpm -F=evault-core test            # eVault Core tests

# Build specific packages
pnpm -F=w3id build                  # Build W3ID (Node.js and browser versions)
pnpm -F=evault-core build           # Build eVault Core
```

### Code Quality Commands

```bash
# Format code across all packages
pnpm format

# Check formatting without making changes
pnpm check-format

# Lint all packages
pnpm lint

# Check linting without fixing
pnpm check-lint

# TypeScript type checking
pnpm check-types

# Run all quality checks
pnpm check
```

---

## Working with Docker and Docker Compose

The project includes Docker configurations for containerized development, particularly useful for the eVault Core service which requires a Neo4j database.

### eVault Development with Docker

The primary Docker setup focuses on the eVault Core service with its Neo4j database dependency:

#### Quick Start with Docker

```bash
# Start eVault Core with Neo4j in development mode with file watching
pnpm dev:evault

# This is equivalent to:
docker compose -f evault.docker-compose.yml up --watch
```

#### Docker Services Overview

The `evault.docker-compose.yml` file defines two main services:

##### 1. eVault Core Service (`evault`)
- **Port**: 4000 (mapped to host)
- **File Watching**: Automatically restarts on code changes
- **Volume**: Persistent secrets storage
- **Dependencies**: Requires Neo4j database

##### 2. Neo4j Database Service (`neo4j`)
- **Ports**: 
  - 7474 (HTTP interface)
  - 7687 (Bolt protocol)
- **Version**: Neo4j 5.15
- **Volumes**: Persistent data and logs storage

#### Docker Development Workflow

```bash
# Start services with file watching (recommended for development)
pnpm dev:evault

# Start services in detached mode
docker compose -f evault.docker-compose.yml up -d

# View logs
docker compose -f evault.docker-compose.yml logs -f

# Stop services
docker compose -f evault.docker-compose.yml down

# Rebuild and restart services
docker compose -f evault.docker-compose.yml up --build

# Clean up everything (including volumes)
docker compose -f evault.docker-compose.yml down -v
```

#### File Watching and Hot Reload

The Docker setup includes sophisticated file watching:

- **Sync + Restart**: Changes to `/infrastructure/evault-core/` (excluding node_modules) trigger service restart
- **Rebuild**: Changes to `package.json` files trigger complete container rebuild
- **Environment**: Changes to `.env` file trigger container rebuild

#### Accessing Services

Once running, you can access:

- **eVault GraphQL API**: http://localhost:4000/graphql
- **eVault Voyager**: http://localhost:4000/voyager (GraphQL schema visualization)
- **eVault Documentation**: http://localhost:4000/documentation
- **Neo4j Browser**: http://localhost:7474 (login with configured credentials)

### Docker Production Build

For production-like builds, use the production Dockerfile:

```bash
# Build production image
docker build -f docker/Dockerfile.evault-prod -t evault-core:prod .

# Note: The production Dockerfile currently has a placeholder CMD
# You may need to modify it based on your deployment requirements
```

### Docker Troubleshooting

#### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using the ports
   netstat -tulpn | grep :4000
   netstat -tulpn | grep :7474
   netstat -tulpn | grep :7687
   ```

2. **Permission Issues** (Linux)
   ```bash
   # Add your user to docker group
   sudo usermod -aG docker $USER
   # Log out and back in for changes to take effect
   ```

3. **Clean Start** (if having issues)
   ```bash
   # Remove all containers, networks, and volumes
   docker compose -f evault.docker-compose.yml down -v
   docker system prune -a
   pnpm dev:evault
   ```

4. **Neo4j Database Issues**
   ```bash
   # Reset Neo4j data
   docker compose -f evault.docker-compose.yml down -v
   pnpm dev:evault
   ```

---

## Project Structure and Package Organization

### Monorepo Layout

The MetaState Prototype follows a structured monorepo approach:

```
metastate-prototype/
├── infrastructure/          # Core system components
│   ├── w3id/               # Web3 Identity system
│   ├── evault-core/        # Data storage with GraphQL API
│   ├── eid-wallet/         # Tauri-based desktop wallet
│   ├── control-panel/      # SvelteKit monitoring dashboard
│   ├── evault-provisioner/ # eVault instance provisioning
│   └── web3-adapter/       # Blockchain integration service
├── platforms/              # Platform-specific integrations
├── services/               # Utility services
├── packages/               # Shared configuration packages
│   ├── eslint-config/      # ESLint configurations
│   └── typescript-config/  # TypeScript configurations
├── docker/                 # Docker build files
├── docs/                   # Documentation
└── scripts/                # Utility scripts
```

### Key Infrastructure Components

#### W3ID (`infrastructure/w3id/`)
- **Purpose**: Persistent, globally unique identity system
- **Build**: Dual builds for Node.js and browser environments
- **Commands**: `pnpm -F=w3id build`, `pnpm -F=w3id test`, `pnpm -F=w3id dev`

#### eVault Core (`infrastructure/evault-core/`)
- **Purpose**: Secure data storage with Neo4j backend and GraphQL API
- **Dependencies**: Requires Neo4j database (use Docker setup)
- **Commands**: `pnpm -F=evault-core dev`, `pnpm -F=evault-core test`, `pnpm -F=evault-core build`

#### eID Wallet (`infrastructure/eid-wallet/`)
- **Purpose**: Cross-platform desktop identity wallet (Tauri + Svelte)
- **Special Commands**: `pnpm -F=eid-wallet tauri dev`, `pnpm -F=eid-wallet storybook`

#### Control Panel (`infrastructure/control-panel/`)
- **Purpose**: SvelteKit-based monitoring and administration interface
- **Commands**: `pnpm -F=control-panel dev`

---

## Testing

### Running Tests

```bash
# Run all tests across the monorepo
pnpm test

# Run tests for specific packages
pnpm -F=w3id test           # W3ID unit tests
pnpm -F=evault-core test    # eVault Core integration tests with TestContainers
```

### Test Infrastructure

- **Unit Tests**: Vitest for all TypeScript packages
- **Integration Tests**: TestContainers for database-dependent components
- **Component Tests**: Storybook for UI components

---

## Deployment and Building

### Building for Production

```bash
# Build all packages
pnpm build

# Build specific services
pnpm -F=evault-core build   # Compiles TypeScript to JavaScript
pnpm -F=w3id build          # Builds both Node.js and browser versions
```

### Production Docker Images

```bash
# Build production eVault Core image
docker build -f docker/Dockerfile.evault-prod -t evault-core:latest .
```

---

## Additional Resources

### Development Scripts

The project includes several utility scripts in the `scripts/` directory:

- `scripts/expose-ports.sh` - Port forwarding utilities
- `forward-local-net.sh` - Local network configuration

### Documentation and Architecture

- **Architecture Diagrams**: See [docs/README.md](README.md) for C4 model diagrams
- **Strategic Analysis**: [thoughts-on-transforming-to-elixir.md](thoughts-on-transforming-to-elixir.md)

### Troubleshooting

#### Common Development Issues

1. **Node Version**: Ensure you're using Node.js ≥18
2. **pnpm Version**: Use the exact version specified in package.json (10.13.1)
3. **Docker Issues**: Make sure Docker is running and you have sufficient permissions
4. **Port Conflicts**: Check that ports 4000, 7474, and 7687 are available
5. **Build Failures**: Try `pnpm install` and `pnpm build` from the root directory

#### Getting Help

- Check existing documentation in the `docs/` directory
- Review package-specific README files in each infrastructure component
- Examine the GitHub issue templates in `.github/ISSUE_TEMPLATE/`

---

This guide covers the essential aspects of working with the MetaState Prototype codebase. For more detailed information about specific components, refer to their individual README files and the architecture documentation in the `docs/` directory.
