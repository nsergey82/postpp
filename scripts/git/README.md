# Git Scripts for MetaState Prototype

This directory contains a collection of shell scripts that simplify common git operations for the MetaState Prototype project. The scripts provide a unified, project-specific workflow that integrates with the project's development practices.

## Quick Start

### Unified Interface

Use the master script for most operations:

```bash
# Quick commit with automatic quality checks
./scripts/git/git.sh commit "feat: add new eVault integration" --push

# Check repository status and sync
./scripts/git/git.sh status --sync

# Create and switch to new branch
./scripts/git/git.sh branch create feature/w3id-improvements

# Create a release
./scripts/git/git.sh release v1.2.3 --dry-run
```

### Individual Scripts

Each script can also be used directly:

```bash
./scripts/git/quick-commit.sh "fix: resolve connection issue" --push
./scripts/git/branch-manager.sh create feature/new-feature
./scripts/git/sync-status.sh --fetch --sync
./scripts/git/release.sh patch --dry-run
./scripts/git/git-utils.sh cleanup
```

## Available Scripts

### 1. Master Script (`git.sh`)

The unified interface that routes commands to appropriate scripts.

**Usage**: `./scripts/git/git.sh [command] [args...]`

**Commands**:
- `commit` - Route to quick-commit script
- `status` - Route to sync-status script
- `branch` - Route to branch-manager script
- `release` - Route to release script
- `cleanup`, `backup`, `contributors`, `config`, `hooks`, `archive` - Route to git-utils

### 2. Quick Commit (`quick-commit.sh`)

Streamlines the commit process with automatic quality checks and optional push.

**Features**:
- Stages all changes automatically
- Runs code quality checks (formatting, linting) if pnpm is available
- Auto-fixes formatting and linting issues when possible
- Supports immediate push to remote
- Colored output with clear status messages

**Usage**:
```bash
./scripts/git/quick-commit.sh "commit message" [--push]
```

**Examples**:
```bash
# Basic commit
./scripts/git/quick-commit.sh "feat: implement user authentication"

# Commit and push
./scripts/git/quick-commit.sh "fix: resolve database connection issue" --push
./scripts/git/quick-commit.sh "docs: update API documentation" -p
```

### 3. Branch Manager (`branch-manager.sh`)

Comprehensive branch management with safety checks and conventions.

**Features**:
- Create branches from latest main/master
- Switch between local and remote branches
- Safe branch deletion with confirmations
- List all branches with status indicators
- Clean up merged branches automatically
- Show detailed branch information

**Usage**:
```bash
./scripts/git/branch-manager.sh [action] [branch-name]
```

**Actions**:
- `create <name>` - Create and switch to new branch
- `switch <name>` - Switch to existing branch  
- `delete <name>` - Delete a branch (with safety checks)
- `list` - List all branches with status
- `clean` - Clean up merged branches
- `current` - Show current branch information

**Branch Naming Conventions**:
- `feature/name` - New features
- `fix/name` - Bug fixes
- `docs/name` - Documentation changes
- `refactor/name` - Code refactoring
- `test/name` - Testing improvements

**Examples**:
```bash
# Create feature branch
./scripts/git/branch-manager.sh create feature/evault-optimization

# Switch to main branch
./scripts/git/branch-manager.sh switch main

# Delete old branch
./scripts/git/branch-manager.sh delete feature/old-feature

# List all branches
./scripts/git/branch-manager.sh list

# Clean up merged branches
./scripts/git/branch-manager.sh clean
```

### 4. Sync Status (`sync-status.sh`)

Comprehensive repository status analysis with optional synchronization.

**Features**:
- Detailed repository and branch information
- Working directory status with file categorization
- Stash status and management suggestions
- Recent commit history
- Branch analysis (ahead/behind status)
- Automatic sync capabilities
- Suggested next actions

**Usage**:
```bash
./scripts/git/sync-status.sh [--sync] [--fetch]
```

**Options**:
- `--sync, -s` - Automatically pull/push to sync with remote
- `--fetch, -f` - Fetch from all remotes before analysis
- `--help, -h` - Show help message

**Examples**:
```bash
# Show status
./scripts/git/sync-status.sh

# Fetch latest and show status
./scripts/git/sync-status.sh --fetch

# Auto-sync with remote
./scripts/git/sync-status.sh --sync

# Fetch and sync
./scripts/git/sync-status.sh --fetch --sync
```

### 5. Release Manager (`release.sh`)

Automated release creation with changelog generation and version management.

**Features**:
- Semantic version support (major.minor.patch)
- Automatic version incrementing
- Pre-flight safety checks
- Build and test validation
- Automatic changelog generation from commit messages
- Git tag creation with release notes
- Dry-run mode for testing

**Usage**:
```bash
./scripts/git/release.sh [version] [options]
```

**Version Formats**:
- `v1.0.0` or `1.0.0` - Specific semantic version
- `major` - Bump major version (1.0.0 → 2.0.0)
- `minor` - Bump minor version (1.0.0 → 1.1.0)
- `patch` - Bump patch version (1.0.0 → 1.0.1)

**Options**:
- `--dry-run` - Show what would be done without executing
- `--force` - Force release even with uncommitted changes
- `--no-build` - Skip build and test steps
- `--help` - Show detailed help

**Examples**:
```bash
# Create patch release (dry run)
./scripts/git/release.sh patch --dry-run

# Create specific version
./scripts/git/release.sh v1.2.3

# Force release with uncommitted changes
./scripts/git/release.sh minor --force --no-build
```

### 6. Git Utilities (`git-utils.sh`)

Collection of maintenance and utility functions.

**Features**:
- Repository cleanup (merged branches, stashes, garbage collection)
- Hard reset capabilities (DESTRUCTIVE)
- Branch backup creation
- Large file detection in git history
- Contributor statistics
- Git configuration management
- Git hooks installation
- Archive creation

**Usage**:
```bash
./scripts/git/git-utils.sh [command] [args...]
```

**Commands**:
- `cleanup` - Clean up repository (merged branches, stashes, etc.)
- `reset-hard` - Reset repository to clean state (**DESTRUCTIVE**)
- `backup-branch` - Create backup of current branch
- `find-large` - Find large files in git history
- `contributors` - Show repository contributor statistics
- `config` - Show/update git configuration
- `hooks` - Install/update git hooks
- `archive <ref>` - Create archive of specific ref/branch/tag

**Examples**:
```bash
# Clean up repository
./scripts/git/git-utils.sh cleanup

# Create branch backup
./scripts/git/git-utils.sh backup-branch

# Show contributors
./scripts/git/git-utils.sh contributors

# Install git hooks
./scripts/git/git-utils.sh hooks

# Create archive
./scripts/git/git-utils.sh archive v1.0.0
```

## Integration with MetaState Prototype

### Code Quality Integration

The scripts integrate with the project's code quality tools:

- **Automatic formatting**: Runs `pnpm format` if formatting issues detected
- **Linting**: Runs `pnpm lint` to fix linting issues
- **Type checking**: Validates TypeScript compilation
- **Build validation**: Ensures `pnpm build` succeeds before releases
- **Test validation**: Runs `pnpm test` before releases

### Project Conventions

The scripts enforce and support project conventions:

- **Conventional commits**: Commit message validation in git hooks
- **Branch naming**: Suggested naming conventions for different types of work
- **Release process**: Automated changelog generation from commit messages
- **Quality gates**: Pre-commit and pre-release quality checks

### Git Hooks

The utilities can install project-specific git hooks:

- **Pre-commit**: Runs formatting and linting checks
- **Commit-msg**: Validates conventional commit format

Install hooks with:
```bash
./scripts/git/git-utils.sh hooks
```

## Safety Features

All scripts include safety features:

- **Repository validation**: Ensure you're in a git repository
- **Branch protection**: Prevent deletion of main/master branches
- **Confirmation prompts**: Ask before destructive operations
- **Backup creation**: Offer to create backups before risky operations
- **Dry-run modes**: Test operations before execution
- **Colored output**: Clear status indication with colors

## Troubleshooting

### Common Issues

1. **Permission denied**: Make scripts executable:
   ```bash
   chmod +x scripts/git/*.sh
   ```

2. **pnpm not found**: Scripts will skip quality checks if pnpm is unavailable
   ```bash
   npm install -g pnpm
   ```

3. **Script not found**: Run from project root:
   ```bash
   # From project root
   ./scripts/git/git.sh status
   ```

### Getting Help

- Show general help: `./scripts/git/git.sh --help`
- Show script-specific help: `./scripts/git/git.sh help <script-name>`
- Show individual script help: `./scripts/git/<script-name>.sh --help`

## Examples Workflows

### Daily Development
```bash
# Check status
./scripts/git/git.sh status

# Create feature branch
./scripts/git/git.sh branch create feature/new-integration

# Make changes, then quick commit
./scripts/git/git.sh commit "feat: implement new integration"

# Push when ready
./scripts/git/git.sh commit "fix: address review feedback" --push
```

### Release Process
```bash
# Ensure clean state
./scripts/git/git.sh status --sync

# Create release (dry run first)
./scripts/git/git.sh release minor --dry-run

# Create actual release
./scripts/git/git.sh release minor
```

### Repository Maintenance
```bash
# Clean up merged branches and optimize repo
./scripts/git/git.sh cleanup

# Check contributor stats
./scripts/git/git.sh contributors

# Install/update git hooks
./scripts/git/git.sh hooks
```

## Customization

The scripts can be customized by modifying the variables at the top of each script:

- **Colors**: Modify color codes for different output types
- **Default behaviors**: Change default options
- **Quality checks**: Modify which quality checks to run
- **Branch conventions**: Update branch naming patterns

## Contributing

When contributing to these scripts:

1. Follow the existing code style and patterns
2. Include proper error handling and user feedback
3. Add colored output for better user experience
4. Include safety checks for destructive operations
5. Update this README with any new features
6. Test scripts thoroughly before committing

The scripts are designed to be self-contained and not require external dependencies beyond standard Unix tools and the project's existing tooling (pnpm, git).
