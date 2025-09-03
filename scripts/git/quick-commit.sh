#!/bin/bash

# Quick commit script for MetaState Prototype
# Usage: ./scripts/git/quick-commit.sh "commit message" [--push]
# Example: ./scripts/git/quick-commit.sh "fix: resolve eVault connection issue" --push

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Check for commit message
if [ -z "$1" ]; then
    print_error "Commit message is required!"
    echo "Usage: $0 \"commit message\" [--push]"
    echo "Example: $0 \"feat: add new eVault integration\" --push"
    exit 1
fi

COMMIT_MSG="$1"
SHOULD_PUSH="$2"

print_status "Starting quick commit process..."

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
    print_warning "No changes detected to commit"
    exit 0
fi

# Show what will be staged
print_status "Files that will be staged:"
git diff --name-only --cached
git diff --name-only

# Stage all changes
print_status "Staging all changes..."
git add .

# Check if pre-commit checks should be run
if command -v pnpm &> /dev/null; then
    print_status "Running code quality checks..."
    
    # Run formatting and linting
    if pnpm check-format &> /dev/null; then
        print_success "Code formatting is valid"
    else
        print_warning "Code formatting issues detected, running formatter..."
        pnpm format
        git add .
    fi
    
    if pnpm check-lint &> /dev/null; then
        print_success "Code linting passed"
    else
        print_warning "Linting issues detected, attempting to fix..."
        pnpm lint || print_warning "Some linting issues may require manual attention"
        git add .
    fi
else
    print_warning "pnpm not found, skipping code quality checks"
fi

# Commit changes
print_status "Committing changes with message: '$COMMIT_MSG'"
git commit -m "$COMMIT_MSG"
print_success "Changes committed successfully!"

# Push if requested
if [ "$SHOULD_PUSH" = "--push" ] || [ "$SHOULD_PUSH" = "-p" ]; then
    print_status "Pushing to remote repository..."
    
    # Get current branch name
    CURRENT_BRANCH=$(git branch --show-current)
    
    # Check if remote branch exists
    if git ls-remote --exit-code --heads origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
        git push origin "$CURRENT_BRANCH"
        print_success "Pushed to origin/$CURRENT_BRANCH"
    else
        print_status "Remote branch doesn't exist, creating and pushing..."
        git push -u origin "$CURRENT_BRANCH"
        print_success "Created and pushed to origin/$CURRENT_BRANCH"
    fi
fi

print_success "Quick commit completed!"

# Show recent commit
echo ""
print_status "Recent commit:"
git log --oneline -1
