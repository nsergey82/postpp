#!/bin/bash

# Git utilities script for MetaState Prototype
# Usage: ./scripts/git/git-utils.sh [command] [args...]
# Example: ./scripts/git/git-utils.sh cleanup

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

# Function to show usage
show_usage() {
    echo "Git Utilities for MetaState Prototype"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  cleanup             - Clean up repository (merged branches, stashes, etc.)"
    echo "  reset-hard          - Reset repository to clean state (DESTRUCTIVE)"
    echo "  backup-branch       - Create backup of current branch"
    echo "  find-large          - Find large files in git history"
    echo "  contributors        - Show repository contributors statistics"
    echo "  config              - Show/update git configuration for this project"
    echo "  hooks               - Install/update git hooks"
    echo "  archive <ref>       - Create archive of specific ref/branch/tag"
    echo ""
    echo "Examples:"
    echo "  $0 cleanup"
    echo "  $0 reset-hard"
    echo "  $0 backup-branch"
    echo "  $0 find-large"
    echo "  $0 contributors"
    echo "  $0 archive v1.0.0"
}

# Function to clean up repository
cleanup_repo() {
    print_header "Repository Cleanup"
    
    # Clean merged branches
    print_status "Cleaning up merged branches..."
    
    MAIN_BRANCH="main"
    if ! git branch | grep -q "$MAIN_BRANCH"; then
        MAIN_BRANCH="master"
    fi
    
    MERGED_BRANCHES=$(git branch --merged "$MAIN_BRANCH" | grep -v "$MAIN_BRANCH" | grep -v "*" | xargs 2>/dev/null || echo "")
    
    if [ -n "$MERGED_BRANCHES" ]; then
        print_warning "Found merged branches to delete:"
        for branch in $MERGED_BRANCHES; do
            echo "  - $branch"
        done
        
        read -p "Delete these branches? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for branch in $MERGED_BRANCHES; do
                git branch -d "$branch"
                print_success "Deleted branch '$branch'"
            done
        fi
    else
        print_success "No merged branches to clean up"
    fi
    
    # Clean up remote tracking branches
    print_status "Pruning remote tracking branches..."
    git remote prune origin
    
    # Garbage collection
    print_status "Running git garbage collection..."
    git gc --prune=now
    
    # Clean up old stashes (older than 30 days)
    print_status "Checking for old stashes..."
    STASH_COUNT=$(git stash list | wc -l)
    if [ "$STASH_COUNT" -gt 5 ]; then
        print_warning "$STASH_COUNT stashes found"
        git stash list
        read -p "Clean up stashes older than 30 days? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # This is a bit complex, so we'll just warn the user
            print_warning "Please review stashes manually with 'git stash list'"
            print_status "Use 'git stash drop stash@{n}' to remove specific stashes"
        fi
    fi
    
    print_success "Repository cleanup completed"
}

# Function to reset repository (DESTRUCTIVE)
reset_hard() {
    print_header "Hard Repository Reset"
    print_error "⚠️  WARNING: This will destroy all uncommitted changes!"
    print_error "This action cannot be undone!"
    
    echo ""
    print_status "This will:"
    echo "  • Discard all uncommitted changes"
    echo "  • Remove all untracked files"
    echo "  • Reset to HEAD"
    echo "  • Clean working directory"
    
    echo ""
    read -p "Are you absolutely sure? Type 'YES' to confirm: " -r
    if [ "$REPLY" != "YES" ]; then
        print_status "Reset cancelled"
        return
    fi
    
    print_status "Resetting repository..."
    
    # Reset to HEAD
    git reset --hard HEAD
    
    # Clean untracked files and directories
    git clean -fd
    
    # Remove ignored files too
    read -p "Also remove ignored files? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git clean -fdx
    fi
    
    print_success "Repository reset completed"
}

# Function to backup current branch
backup_branch() {
    local current_branch=$(git branch --show-current)
    local backup_name="backup-${current_branch}-$(date +%Y%m%d-%H%M%S)"
    
    print_header "Branch Backup"
    print_status "Creating backup of branch '$current_branch' as '$backup_name'"
    
    git branch "$backup_name"
    print_success "Created backup branch '$backup_name'"
    
    # Offer to push backup
    read -p "Push backup branch to remote? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin "$backup_name"
        print_success "Pushed backup to origin/$backup_name"
    fi
}

# Function to find large files in git history
find_large_files() {
    print_header "Large Files in Git History"
    print_status "Scanning git history for large files (this may take a while)..."
    
    # Find large files (>1MB) in git history
    git rev-list --objects --all \
    | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
    | sed -n 's/^blob //p' \
    | sort --numeric-sort --key=2 \
    | tail -20 \
    | while read objectname size path; do
        if [ "$size" -gt 1048576 ]; then  # 1MB
            size_mb=$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "$size bytes")
            echo "$(printf "%8s MB" "$size_mb") $path"
        fi
    done
}

# Function to show contributor statistics
show_contributors() {
    print_header "Repository Contributors"
    
    print_status "Top contributors by commits:"
    git shortlog -sn | head -10
    
    echo ""
    print_status "Recent activity (last 30 days):"
    git shortlog -sn --since="30 days ago"
    
    echo ""
    print_status "Lines of code by contributor:"
    git ls-files | grep -E '\.(js|ts|json|md|sh)$' | head -20 | while read file; do
        if [ -f "$file" ]; then
            git blame --line-porcelain "$file" 2>/dev/null | grep "^author " | sort | uniq -c | sort -nr
        fi
    done | head -10 | while read count author; do
        echo "$count lines by $author"
    done 2>/dev/null || echo "Could not analyze lines of code"
}

# Function to show/update git configuration
manage_config() {
    print_header "Git Configuration for MetaState Prototype"
    
    print_status "Current repository configuration:"
    echo "Repository: $(git config --local user.name 2>/dev/null || echo 'Not set')"
    echo "Email: $(git config --local user.email 2>/dev/null || echo 'Not set')"
    echo "Default branch: $(git config --local init.defaultBranch 2>/dev/null || echo 'Not set')"
    echo "Pull strategy: $(git config --local pull.rebase 2>/dev/null || echo 'Not set')"
    
    echo ""
    print_status "Recommended settings for this project:"
    echo "  • Pull with rebase: git config pull.rebase true"
    echo "  • Auto-prune on fetch: git config fetch.prune true"
    echo "  • Default branch: main"
    
    echo ""
    read -p "Apply recommended settings? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git config pull.rebase true
        git config fetch.prune true
        git config init.defaultBranch main
        print_success "Applied recommended git configuration"
    fi
}

# Function to install/update git hooks
install_hooks() {
    print_header "Git Hooks Setup"
    
    local hooks_dir=".git/hooks"
    local project_hooks_dir="scripts/git/hooks"
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$project_hooks_dir"
    
    # Pre-commit hook
    local pre_commit_hook="$hooks_dir/pre-commit"
    
    print_status "Setting up pre-commit hook..."
    
    cat > "$pre_commit_hook" << 'EOF'
#!/bin/bash
# Pre-commit hook for MetaState Prototype

echo "Running pre-commit checks..."

# Check if pnpm is available
if command -v pnpm &> /dev/null; then
    echo "Running code quality checks..."
    
    # Run formatting check
    if ! pnpm check-format; then
        echo "❌ Code formatting issues detected"
        echo "Run 'pnpm format' to fix formatting issues"
        exit 1
    fi
    
    # Run linting
    if ! pnpm check-lint; then
        echo "❌ Linting issues detected"
        echo "Run 'pnpm lint' to fix linting issues"
        exit 1
    fi
    
    echo "✅ Pre-commit checks passed"
else
    echo "⚠️  pnpm not found, skipping code quality checks"
fi
EOF
    
    chmod +x "$pre_commit_hook"
    print_success "Installed pre-commit hook"
    
    # Commit message hook
    local commit_msg_hook="$hooks_dir/commit-msg"
    
    print_status "Setting up commit message hook..."
    
    cat > "$commit_msg_hook" << 'EOF'
#!/bin/bash
# Commit message hook for MetaState Prototype

commit_regex='^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Commit messages should follow conventional commits format:"
    echo "  type(scope): description"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, test, chore"
    echo "Examples:"
    echo "  feat: add new eVault encryption method"
    echo "  fix(w3id): resolve key rotation issue"
    echo "  docs: update API documentation"
    echo "  chore: update dependencies"
    echo ""
    exit 1
fi
EOF
    
    chmod +x "$commit_msg_hook"
    print_success "Installed commit message hook"
    
    print_status "Git hooks installed successfully!"
}

# Function to create archive
create_archive() {
    local ref="$1"
    
    if [ -z "$ref" ]; then
        print_error "Reference (branch/tag/commit) is required for archive"
        return 1
    fi
    
    print_header "Creating Archive"
    
    # Verify ref exists
    if ! git rev-parse --verify "$ref" >/dev/null 2>&1; then
        print_error "Reference '$ref' not found"
        return 1
    fi
    
    local archive_name="metastate-prototype-${ref}-$(date +%Y%m%d-%H%M%S)"
    local archive_file="${archive_name}.tar.gz"
    
    print_status "Creating archive '$archive_file' from '$ref'..."
    
    git archive --format=tar.gz --prefix="${archive_name}/" "$ref" > "$archive_file"
    
    print_success "Created archive: $archive_file"
    print_status "Archive size: $(du -h "$archive_file" | cut -f1)"
}

# Main script logic
case "$1" in
    "cleanup")
        cleanup_repo
        ;;
    "reset-hard")
        reset_hard
        ;;
    "backup-branch")
        backup_branch
        ;;
    "find-large")
        find_large_files
        ;;
    "contributors")
        show_contributors
        ;;
    "config")
        manage_config
        ;;
    "hooks")
        install_hooks
        ;;
    "archive")
        create_archive "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
