#!/bin/bash

# Release management script for MetaState Prototype
# Usage: ./scripts/git/release.sh [version] [--dry-run]
# Example: ./scripts/git/release.sh v1.2.3 --dry-run

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
    echo "Release Manager for MetaState Prototype"
    echo ""
    echo "Usage: $0 [version] [options]"
    echo ""
    echo "Version formats:"
    echo "  v1.0.0          - Full semantic version"
    echo "  1.0.0           - Semantic version (v will be added)"
    echo "  major           - Bump major version (1.0.0 -> 2.0.0)"
    echo "  minor           - Bump minor version (1.0.0 -> 1.1.0)"
    echo "  patch           - Bump patch version (1.0.0 -> 1.0.1)"
    echo ""
    echo "Options:"
    echo "  --dry-run       - Show what would be done without executing"
    echo "  --force         - Force release even with uncommitted changes"
    echo "  --no-build      - Skip build and test steps"
    echo "  --help          - Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Validate repository state"
    echo "  2. Run tests and build"
    echo "  3. Update version numbers"
    echo "  4. Create git tag"
    echo "  5. Generate changelog"
    echo "  6. Push to remote"
}

# Parse command line arguments
VERSION=""
DRY_RUN=false
FORCE=false
NO_BUILD=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $arg"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$arg"
            else
                print_error "Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate version argument
if [ -z "$VERSION" ]; then
    print_error "Version is required"
    show_usage
    exit 1
fi

# Function to get current version from package.json or git tags
get_current_version() {
    # Try to get from git tags first
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$latest_tag" ]; then
        echo "$latest_tag" | sed 's/^v//'
    else
        echo "0.0.0"
    fi
}

# Function to validate semantic version
validate_semver() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

# Function to increment version
increment_version() {
    local current="$1"
    local bump_type="$2"
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    
    case "$bump_type" in
        "major")
            echo "$((major + 1)).0.0"
            ;;
        "minor")
            echo "$major.$((minor + 1)).0"
            ;;
        "patch")
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            echo "Invalid bump type: $bump_type" >&2
            return 1
            ;;
    esac
}

# Determine target version
CURRENT_VERSION=$(get_current_version)
TARGET_VERSION=""

case "$VERSION" in
    "major"|"minor"|"patch")
        TARGET_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION")
        if [ $? -ne 0 ]; then
            print_error "Failed to increment version"
            exit 1
        fi
        ;;
    v*)
        TARGET_VERSION="${VERSION#v}"
        ;;
    *)
        TARGET_VERSION="$VERSION"
        ;;
esac

# Validate target version
if ! validate_semver "$TARGET_VERSION"; then
    print_error "Invalid semantic version: $TARGET_VERSION"
    print_status "Version must be in format: major.minor.patch (e.g., 1.2.3)"
    exit 1
fi

# Add v prefix for tags
TAG_VERSION="v$TARGET_VERSION"

print_header "Release Planning"
echo "Current version: $CURRENT_VERSION"
echo "Target version:  $TARGET_VERSION"
echo "Git tag:         $TAG_VERSION"

if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN MODE - No changes will be made"
fi

# Pre-flight checks
print_header "Pre-flight Checks"

# Check if we're on main/master branch
CURRENT_BRANCH=$(git branch --show-current)
MAIN_BRANCH="main"
if ! git branch | grep -q "$MAIN_BRANCH"; then
    MAIN_BRANCH="master"
fi

if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
    print_warning "Not on $MAIN_BRANCH branch (currently on $CURRENT_BRANCH)"
    if [ "$FORCE" != true ]; then
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Release cancelled"
            exit 1
        fi
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    print_warning "Uncommitted changes detected"
    if [ "$FORCE" != true ]; then
        print_error "Please commit or stash changes before creating a release"
        print_status "Use --force to override this check"
        exit 1
    else
        print_warning "Proceeding with uncommitted changes due to --force flag"
    fi
fi

# Check if tag already exists
if git tag | grep -q "^$TAG_VERSION$"; then
    print_error "Tag $TAG_VERSION already exists"
    exit 1
fi

# Fetch latest from remote
print_status "Fetching latest changes from remote..."
if [ "$DRY_RUN" != true ]; then
    git fetch origin "$CURRENT_BRANCH"
fi

# Check if we're up to date with remote
AHEAD_BEHIND=$(git rev-list --left-right --count HEAD...origin/"$CURRENT_BRANCH" 2>/dev/null || echo "0	0")
AHEAD=$(echo "$AHEAD_BEHIND" | cut -f1)
BEHIND=$(echo "$AHEAD_BEHIND" | cut -f2)

if [ "$BEHIND" -gt 0 ]; then
    print_warning "Branch is $BEHIND commits behind origin/$CURRENT_BRANCH"
    if [ "$FORCE" != true ]; then
        print_error "Please pull latest changes before creating a release"
        exit 1
    fi
fi

print_success "Pre-flight checks passed"

# Build and test
if [ "$NO_BUILD" != true ]; then
    print_header "Build and Test"
    
    if command -v pnpm &> /dev/null; then
        print_status "Running code quality checks..."
        if [ "$DRY_RUN" != true ]; then
            pnpm check || {
                print_error "Code quality checks failed"
                exit 1
            }
        fi
        print_success "Code quality checks passed"
        
        print_status "Building all packages..."
        if [ "$DRY_RUN" != true ]; then
            pnpm build || {
                print_error "Build failed"
                exit 1
            }
        fi
        print_success "Build completed"
        
        print_status "Running tests..."
        if [ "$DRY_RUN" != true ]; then
            pnpm test || {
                print_error "Tests failed"
                exit 1
            }
        fi
        print_success "Tests passed"
    else
        print_warning "pnpm not found, skipping build and test steps"
    fi
fi

# Generate changelog
print_header "Changelog Generation"
CHANGELOG_FILE="CHANGELOG.md"
TEMP_CHANGELOG="/tmp/metastate-changelog-$TARGET_VERSION.md"

if [ -f "$CHANGELOG_FILE" ]; then
    print_status "Updating existing changelog..."
else
    print_status "Creating new changelog..."
fi

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    COMMIT_RANGE="$LAST_TAG..HEAD"
    print_status "Generating changelog for commits since $LAST_TAG"
else
    COMMIT_RANGE="HEAD"
    print_status "Generating changelog for all commits"
fi

# Generate changelog content
{
    echo "## [$TAG_VERSION] - $(date +%Y-%m-%d)"
    echo ""
    
    # Categorize commits
    echo "### Added"
    git log "$COMMIT_RANGE" --grep="^feat" --grep="^add" --oneline --no-merges | sed 's/^[^ ]* /- /' || echo "- No new features"
    echo ""
    
    echo "### Changed"
    git log "$COMMIT_RANGE" --grep="^change" --grep="^update" --oneline --no-merges | sed 's/^[^ ]* /- /' || echo "- No changes"
    echo ""
    
    echo "### Fixed"
    git log "$COMMIT_RANGE" --grep="^fix" --grep="^bug" --oneline --no-merges | sed 's/^[^ ]* /- /' || echo "- No fixes"
    echo ""
    
    echo "### Infrastructure"
    git log "$COMMIT_RANGE" --grep="^chore" --grep="^ci" --grep="^build" --oneline --no-merges | sed 's/^[^ ]* /- /' || echo "- No infrastructure changes"
    echo ""
} > "$TEMP_CHANGELOG"

print_status "Generated changelog:"
echo ""
cat "$TEMP_CHANGELOG"
echo ""

if [ "$DRY_RUN" != true ]; then
    # Prepend to existing changelog or create new one
    if [ -f "$CHANGELOG_FILE" ]; then
        {
            cat "$TEMP_CHANGELOG"
            echo ""
            cat "$CHANGELOG_FILE"
        } > "${CHANGELOG_FILE}.tmp" && mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
    else
        {
            echo "# Changelog"
            echo ""
            echo "All notable changes to MetaState Prototype will be documented in this file."
            echo ""
            cat "$TEMP_CHANGELOG"
        } > "$CHANGELOG_FILE"
    fi
    
    # Stage the changelog
    git add "$CHANGELOG_FILE"
    print_success "Updated $CHANGELOG_FILE"
fi

# Create release commit and tag
print_header "Creating Release"

if [ "$DRY_RUN" != true ]; then
    # Commit changelog
    if ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
        git commit -m "chore: prepare release $TAG_VERSION"
        print_success "Created release commit"
    fi
    
    # Create annotated tag
    git tag -a "$TAG_VERSION" -m "Release $TAG_VERSION

$(cat "$TEMP_CHANGELOG")"
    print_success "Created git tag $TAG_VERSION"
    
    # Push tag and commits
    print_status "Pushing to remote..."
    git push origin "$CURRENT_BRANCH"
    git push origin "$TAG_VERSION"
    print_success "Pushed release to remote"
else
    print_status "Would create release commit and tag $TAG_VERSION"
    print_status "Would push to remote origin"
fi

# Cleanup
rm -f "$TEMP_CHANGELOG"

# Final summary
print_header "Release Summary"
print_success "Release $TAG_VERSION completed successfully!"

if [ "$DRY_RUN" != true ]; then
    echo ""
    print_status "Next steps:"
    echo "  • Verify the release on your repository hosting platform"
    echo "  • Deploy the release to your environments"
    echo "  • Announce the release to stakeholders"
    echo ""
    print_status "Release information:"
    echo "  Tag: $TAG_VERSION"
    echo "  Commit: $(git rev-parse HEAD)"
    echo "  Date: $(date)"
    
    # Show the tag
    echo ""
    print_status "Tag details:"
    git show "$TAG_VERSION" --no-patch
else
    echo ""
    print_status "This was a dry run - no changes were made"
    print_status "Run without --dry-run to create the actual release"
fi
