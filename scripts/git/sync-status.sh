#!/bin/bash

# Git status and sync script for MetaState Prototype
# Usage: ./scripts/git/sync-status.sh [--sync] [--fetch]
# Example: ./scripts/git/sync-status.sh --sync

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

print_header() {
    echo -e "${MAGENTA}==== $1 ====${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Parse command line arguments
SHOULD_SYNC=false
SHOULD_FETCH=false

for arg in "$@"; do
    case $arg in
        --sync|-s)
            SHOULD_SYNC=true
            shift
            ;;
        --fetch|-f)
            SHOULD_FETCH=true
            shift
            ;;
        --help|-h)
            echo "Git Sync Status for MetaState Prototype"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --sync, -s     Automatically sync with remote (pull/push)"
            echo "  --fetch, -f    Fetch latest from all remotes first"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "This script shows:"
            echo "  - Current repository status"
            echo "  - Branch information and tracking"
            echo "  - Uncommitted changes"
            echo "  - Unpushed/unpulled commits"
            echo "  - Stash status"
            exit 0
            ;;
        *)
            print_warning "Unknown option: $arg (use --help for usage)"
            ;;
    esac
done

# Fetch from remote if requested
if [ "$SHOULD_FETCH" = true ]; then
    print_status "Fetching latest from all remotes..."
    git fetch --all --prune
    print_success "Fetched from all remotes"
    echo ""
fi

# Repository Information
print_header "Repository Information"
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "Repository root: $REPO_ROOT"
echo "Git directory: $(git rev-parse --git-dir)"

# Remote information
echo ""
print_status "Configured remotes:"
if git remote -v | grep -q .; then
    git remote -v | while read remote; do
        echo "  $remote"
    done
else
    print_warning "No remotes configured"
fi

# Current Branch Information
echo ""
print_header "Branch Information"
CURRENT_BRANCH=$(git branch --show-current)
echo -e "Current branch: ${CYAN}$CURRENT_BRANCH${NC}"

# Check if branch has upstream
if git config --get branch."$CURRENT_BRANCH".remote > /dev/null 2>&1; then
    REMOTE=$(git config --get branch."$CURRENT_BRANCH".remote)
    MERGE_BRANCH=$(git config --get branch."$CURRENT_BRANCH".merge | sed 's|refs/heads/||')
    echo "Tracking: $REMOTE/$MERGE_BRANCH"
    
    # Check ahead/behind status
    AHEAD_BEHIND=$(git rev-list --left-right --count HEAD..."$REMOTE"/"$MERGE_BRANCH" 2>/dev/null || echo "0	0")
    AHEAD=$(echo "$AHEAD_BEHIND" | cut -f1)
    BEHIND=$(echo "$AHEAD_BEHIND" | cut -f2)
    
    if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
        print_warning "Branch is $AHEAD commits ahead and $BEHIND commits behind $REMOTE/$MERGE_BRANCH"
    elif [ "$AHEAD" -gt 0 ]; then
        echo -e "${YELLOW}Ahead:${NC} $AHEAD commits ahead of $REMOTE/$MERGE_BRANCH"
    elif [ "$BEHIND" -gt 0 ]; then
        echo -e "${YELLOW}Behind:${NC} $BEHIND commits behind $REMOTE/$MERGE_BRANCH"
    else
        print_success "Up to date with $REMOTE/$MERGE_BRANCH"
    fi
else
    print_warning "No upstream tracking branch configured"
fi

# Working Directory Status
echo ""
print_header "Working Directory Status"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    print_warning "Uncommitted changes detected"
    
    # Staged changes
    if ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
        echo ""
        echo -e "${GREEN}Staged files:${NC}"
        git diff --cached --name-status | while read status file; do
            case $status in
                A) echo "  + $file (new file)" ;;
                M) echo "  ~ $file (modified)" ;;
                D) echo "  - $file (deleted)" ;;
                R*) echo "  → $file (renamed)" ;;
                *) echo "  ? $file ($status)" ;;
            esac
        done
    fi
    
    # Unstaged changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}Unstaged files:${NC}"
        git diff --name-status | while read status file; do
            case $status in
                M) echo "  ~ $file (modified)" ;;
                D) echo "  - $file (deleted)" ;;
                *) echo "  ? $file ($status)" ;;
            esac
        done
    fi
    
    # Untracked files
    UNTRACKED=$(git ls-files --others --exclude-standard)
    if [ -n "$UNTRACKED" ]; then
        echo ""
        echo -e "${CYAN}Untracked files:${NC}"
        echo "$UNTRACKED" | while read file; do
            echo "  ? $file"
        done
    fi
else
    print_success "Working directory is clean"
fi

# Stash Status
echo ""
print_header "Stash Status"
STASH_COUNT=$(git stash list | wc -l)
if [ "$STASH_COUNT" -gt 0 ]; then
    print_warning "$STASH_COUNT stash(es) found"
    echo ""
    echo "Recent stashes:"
    git stash list | head -5 | while read stash; do
        echo "  $stash"
    done
else
    print_success "No stashes"
fi

# Recent Activity
echo ""
print_header "Recent Activity"
echo "Last 5 commits on current branch:"
git log --oneline --graph -5 | while read commit; do
    echo "  $commit"
done

# Show branches that might need attention
echo ""
print_header "Branch Analysis"

# Find branches that might need merging
MAIN_BRANCH="main"
if ! git branch | grep -q "$MAIN_BRANCH"; then
    MAIN_BRANCH="master"
fi

if git branch | grep -q "$MAIN_BRANCH"; then
    # Branches ahead of main
    echo "Branches ahead of $MAIN_BRANCH:"
    git for-each-ref --format='%(refname:short) %(ahead-behind:'"$MAIN_BRANCH"')' refs/heads | while read branch ahead_behind; do
        if [[ "$ahead_behind" =~ ^[1-9][0-9]*" 0"$ ]]; then
            AHEAD=$(echo "$ahead_behind" | cut -d' ' -f1)
            if [ "$branch" != "$MAIN_BRANCH" ]; then
                echo -e "  ${CYAN}$branch${NC} ($AHEAD commits ahead)"
            fi
        fi
    done
    
    # Branches behind main
    echo ""
    echo "Branches behind $MAIN_BRANCH:"
    git for-each-ref --format='%(refname:short) %(ahead-behind:'"$MAIN_BRANCH"')' refs/heads | while read branch ahead_behind; do
        if [[ "$ahead_behind" =~ ^0" "[1-9][0-9]*$ ]]; then
            BEHIND=$(echo "$ahead_behind" | cut -d' ' -f2)
            if [ "$branch" != "$MAIN_BRANCH" ]; then
                echo -e "  ${YELLOW}$branch${NC} ($BEHIND commits behind)"
            fi
        fi
    done
fi

# Sync operations
if [ "$SHOULD_SYNC" = true ]; then
    echo ""
    print_header "Sync Operations"
    
    # Check if we have uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_error "Cannot sync: uncommitted changes detected"
        print_status "Please commit or stash your changes first"
        exit 1
    fi
    
    # Pull if we're behind
    if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
        print_status "Pulling latest changes from $REMOTE/$MERGE_BRANCH..."
        git pull
        print_success "Pulled latest changes"
    fi
    
    # Push if we're ahead
    if [ "$AHEAD" -gt 0 ] 2>/dev/null; then
        print_status "Pushing local commits to $REMOTE/$MERGE_BRANCH..."
        git push
        print_success "Pushed local commits"
    fi
    
    if [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ] 2>/dev/null; then
        print_success "Branch is already in sync"
    fi
fi

# Summary
echo ""
print_header "Summary"
if git diff-index --quiet HEAD -- 2>/dev/null && [ "$STASH_COUNT" -eq 0 ]; then
    print_success "Repository is clean and organized"
else
    print_warning "Repository has uncommitted changes or stashes"
fi

# Suggest next actions
echo ""
print_status "Suggested next actions:"
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "  • Review and commit your changes: git add . && git commit -m 'message'"
    echo "  • Use quick-commit script: ./scripts/git/quick-commit.sh 'commit message'"
fi

if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
    echo "  • Pull latest changes: git pull"
fi

if [ "$AHEAD" -gt 0 ] 2>/dev/null; then
    echo "  • Push your commits: git push"
fi

if [ "$STASH_COUNT" -gt 0 ]; then
    echo "  • Review stashes: git stash list"
    echo "  • Apply latest stash: git stash pop"
fi

echo "  • Use sync with --sync flag to auto-sync: $0 --sync"
