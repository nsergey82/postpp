#!/bin/bash

# Master Git script for MetaState Prototype
# Provides unified access to all git utilities
# Usage: ./scripts/git/git.sh [command] [args...]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${MAGENTA}==== $1 ====${NC}"
}

# Function to show usage
show_usage() {
    echo "Git Management for MetaState Prototype"
    echo ""
    echo "Usage: $0 [command] [args...]"
    echo ""
    echo "Quick Commit & Status:"
    echo "  commit \"message\" [--push]  - Quick commit with quality checks"
    echo "  status [--sync] [--fetch]   - Show detailed repository status"
    echo ""
    echo "Branch Management:"
    echo "  branch create <name>        - Create and switch to new branch"
    echo "  branch switch <name>        - Switch to existing branch"
    echo "  branch delete <name>        - Delete a branch"
    echo "  branch list                 - List all branches"
    echo "  branch clean                - Clean up merged branches"
    echo "  branch current              - Show current branch info"
    echo ""
    echo "Release Management:"
    echo "  release <version> [options] - Create a release with changelog"
    echo "  release --help              - Show release options"
    echo ""
    echo "Repository Utilities:"
    echo "  cleanup                     - Clean up repository (merged branches, etc.)"
    echo "  backup                      - Create backup of current branch"
    echo "  contributors                - Show contributor statistics"
    echo "  config                      - Show/update git configuration"
    echo "  hooks                       - Install git hooks"
    echo "  archive <ref>               - Create archive of branch/tag"
    echo ""
    echo "Examples:"
    echo "  $0 commit \"feat: add new eVault integration\" --push"
    echo "  $0 status --sync"
    echo "  $0 branch create feature/w3id-improvements"
    echo "  $0 branch switch main"
    echo "  $0 release v1.2.3 --dry-run"
    echo "  $0 cleanup"
    echo ""
    echo "Individual script usage:"
    echo "  $0 help <script>            - Show help for specific script"
    echo ""
    echo "Available scripts: commit, branch, status, release, utils"
}

# Function to show help for individual scripts
show_script_help() {
    local script="$1"
    case "$script" in
        "commit"|"quick-commit")
            "$SCRIPT_DIR/quick-commit.sh" --help || echo "Usage: commit \"message\" [--push]"
            ;;
        "branch"|"branch-manager")
            "$SCRIPT_DIR/branch-manager.sh" || true
            ;;
        "status"|"sync-status")
            "$SCRIPT_DIR/sync-status.sh" --help || echo "Usage: status [--sync] [--fetch]"
            ;;
        "release")
            "$SCRIPT_DIR/release.sh" --help || echo "Usage: release <version> [options]"
            ;;
        "utils"|"git-utils")
            "$SCRIPT_DIR/git-utils.sh" || true
            ;;
        *)
            print_error "Unknown script: $script"
            echo "Available scripts: commit, branch, status, release, utils"
            ;;
    esac
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Parse command and route to appropriate script
case "$1" in
    # Quick commit
    "commit"|"c")
        shift
        exec "$SCRIPT_DIR/quick-commit.sh" "$@"
        ;;
    
    # Status and sync
    "status"|"s")
        shift
        exec "$SCRIPT_DIR/sync-status.sh" "$@"
        ;;
    
    # Branch management
    "branch"|"b")
        shift
        exec "$SCRIPT_DIR/branch-manager.sh" "$@"
        ;;
    
    # Release management
    "release"|"r")
        shift
        exec "$SCRIPT_DIR/release.sh" "$@"
        ;;
    
    # Utility functions from git-utils
    "cleanup")
        exec "$SCRIPT_DIR/git-utils.sh" cleanup
        ;;
    "backup")
        exec "$SCRIPT_DIR/git-utils.sh" backup-branch
        ;;
    "contributors")
        exec "$SCRIPT_DIR/git-utils.sh" contributors
        ;;
    "config")
        exec "$SCRIPT_DIR/git-utils.sh" config
        ;;
    "hooks")
        exec "$SCRIPT_DIR/git-utils.sh" hooks
        ;;
    "archive")
        shift
        exec "$SCRIPT_DIR/git-utils.sh" archive "$@"
        ;;
    
    # Help for individual scripts
    "help")
        show_script_help "$2"
        ;;
    
    # Show main usage
    "--help"|"-h"|"")
        show_usage
        ;;
    
    # Unknown command
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
