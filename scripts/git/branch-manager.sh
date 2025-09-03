#!/bin/bash

# Branch management script for MetaState Prototype
# Usage: ./scripts/git/branch-manager.sh [action] [branch-name]
# Actions: create, switch, delete, list, clean
# Example: ./scripts/git/branch-manager.sh create feature/evault-optimization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_branch() {
    echo -e "${CYAN}$1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Branch Manager for MetaState Prototype"
    echo ""
    echo "Usage: $0 [action] [branch-name]"
    echo ""
    echo "Actions:"
    echo "  create <name>    - Create and switch to a new branch"
    echo "  switch <name>    - Switch to an existing branch"
    echo "  delete <name>    - Delete a local branch"
    echo "  list            - List all branches (local and remote)"
    echo "  clean           - Clean up merged branches"
    echo "  current         - Show current branch information"
    echo ""
    echo "Branch naming conventions:"
    echo "  feature/name    - New features"
    echo "  fix/name        - Bug fixes"
    echo "  docs/name       - Documentation changes"
    echo "  refactor/name   - Code refactoring"
    echo "  test/name       - Testing improvements"
    echo ""
    echo "Examples:"
    echo "  $0 create feature/w3id-key-rotation"
    echo "  $0 switch main"
    echo "  $0 delete feature/old-feature"
    echo "  $0 list"
    echo "  $0 clean"
}

# Function to create and switch to new branch
create_branch() {
    local branch_name="$1"
    
    if [ -z "$branch_name" ]; then
        print_error "Branch name is required for create action"
        show_usage
        exit 1
    fi
    
    print_status "Creating branch '$branch_name'..."
    
    # Ensure we're on main/master and up to date
    local main_branch
    if git branch -r | grep -q "origin/main"; then
        main_branch="main"
    elif git branch -r | grep -q "origin/master"; then
        main_branch="master"
    else
        print_error "Could not find main or master branch"
        exit 1
    fi
    
    print_status "Switching to $main_branch and pulling latest changes..."
    git checkout "$main_branch"
    git pull origin "$main_branch"
    
    # Create and switch to new branch
    git checkout -b "$branch_name"
    print_success "Created and switched to branch '$branch_name'"
    
    # Offer to push the branch
    read -p "Push branch to origin? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin "$branch_name"
        print_success "Pushed branch to origin/$branch_name"
    fi
}

# Function to switch to existing branch
switch_branch() {
    local branch_name="$1"
    
    if [ -z "$branch_name" ]; then
        print_error "Branch name is required for switch action"
        show_usage
        exit 1
    fi
    
    print_status "Switching to branch '$branch_name'..."
    
    # Check if branch exists locally
    if git branch | grep -q "$branch_name"; then
        git checkout "$branch_name"
        print_success "Switched to local branch '$branch_name'"
    # Check if branch exists on remote
    elif git branch -r | grep -q "origin/$branch_name"; then
        git checkout -b "$branch_name" "origin/$branch_name"
        print_success "Checked out remote branch '$branch_name'"
    else
        print_error "Branch '$branch_name' not found locally or on remote"
        exit 1
    fi
    
    # Pull latest changes if tracking remote
    if git config --get branch."$branch_name".remote > /dev/null 2>&1; then
        print_status "Pulling latest changes..."
        git pull
    fi
}

# Function to delete branch
delete_branch() {
    local branch_name="$1"
    
    if [ -z "$branch_name" ]; then
        print_error "Branch name is required for delete action"
        show_usage
        exit 1
    fi
    
    # Safety check - don't delete main/master
    if [[ "$branch_name" == "main" ]] || [[ "$branch_name" == "master" ]]; then
        print_error "Cannot delete main/master branch"
        exit 1
    fi
    
    # Safety check - don't delete current branch
    local current_branch=$(git branch --show-current)
    if [[ "$branch_name" == "$current_branch" ]]; then
        print_error "Cannot delete current branch. Switch to another branch first."
        exit 1
    fi
    
    print_warning "This will delete branch '$branch_name'"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Delete local branch
        if git branch | grep -q "$branch_name"; then
            git branch -d "$branch_name" || git branch -D "$branch_name"
            print_success "Deleted local branch '$branch_name'"
        fi
        
        # Ask about remote branch
        if git branch -r | grep -q "origin/$branch_name"; then
            read -p "Delete remote branch too? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push origin --delete "$branch_name"
                print_success "Deleted remote branch 'origin/$branch_name'"
            fi
        fi
    else
        print_status "Branch deletion cancelled"
    fi
}

# Function to list branches
list_branches() {
    print_status "Current branch:"
    print_branch "$(git branch --show-current)"
    
    echo ""
    print_status "Local branches:"
    git branch --format="  %(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)" | while read line; do
        if [[ $line == *"*"* ]]; then
            echo -e "${GREEN}$line${NC}"
        else
            echo -e "${CYAN}$line${NC}"
        fi
    done
    
    echo ""
    print_status "Remote branches:"
    git branch -r --format="  %(refname:short)" | grep -v "HEAD" | while read line; do
        print_branch "$line"
    done
    
    echo ""
    print_status "Recent commits on current branch:"
    git log --oneline -5
}

# Function to clean up merged branches
clean_branches() {
    print_status "Finding merged branches to clean up..."
    
    # Get main branch name
    local main_branch
    if git branch | grep -q "main"; then
        main_branch="main"
    elif git branch | grep -q "master"; then
        main_branch="master"
    else
        print_error "Could not find main or master branch"
        exit 1
    fi
    
    # Find merged branches (excluding main/master and current branch)
    local merged_branches=$(git branch --merged "$main_branch" | grep -v "$main_branch" | grep -v "*" | xargs)
    
    if [ -z "$merged_branches" ]; then
        print_success "No merged branches found to clean up"
        return
    fi
    
    print_warning "The following merged branches will be deleted:"
    for branch in $merged_branches; do
        echo "  - $branch"
    done
    
    read -p "Proceed with cleanup? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for branch in $merged_branches; do
            git branch -d "$branch"
            print_success "Deleted merged branch '$branch'"
        done
    else
        print_status "Branch cleanup cancelled"
    fi
}

# Function to show current branch info
show_current() {
    local current_branch=$(git branch --show-current)
    local commit_count=$(git rev-list --count HEAD)
    local last_commit=$(git log -1 --format="%h - %s (%cr)")
    
    print_status "Current branch information:"
    echo "  Branch: $(print_branch "$current_branch")"
    echo "  Total commits: $commit_count"
    echo "  Last commit: $last_commit"
    
    # Show if branch has upstream
    if git config --get branch."$current_branch".remote > /dev/null 2>&1; then
        local remote=$(git config --get branch."$current_branch".remote)
        local merge_branch=$(git config --get branch."$current_branch".merge | sed 's|refs/heads/||')
        echo "  Tracking: $remote/$merge_branch"
        
        # Show ahead/behind info
        local ahead_behind=$(git rev-list --left-right --count HEAD..."$remote"/"$merge_branch" 2>/dev/null || echo "0	0")
        local ahead=$(echo "$ahead_behind" | cut -f1)
        local behind=$(echo "$ahead_behind" | cut -f2)
        
        if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
            echo "  Status: ${ahead} ahead, ${behind} behind"
        else
            echo "  Status: Up to date"
        fi
    else
        echo "  Tracking: No upstream configured"
    fi
}

# Main script logic
case "$1" in
    "create")
        create_branch "$2"
        ;;
    "switch")
        switch_branch "$2"
        ;;
    "delete")
        delete_branch "$2"
        ;;
    "list")
        list_branches
        ;;
    "clean")
        clean_branches
        ;;
    "current")
        show_current
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
