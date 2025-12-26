#!/bin/bash
#
# ═══════════════════════════════════════════════════════════════════════════════
# ViteSEO Auto-Deploy Installation Script
# ═══════════════════════════════════════════════════════════════════════════════
#
# This script installs the GitHub Actions deployment workflow and scripts
# into your git repository for automatic SSH-based deployments.
#
# ═══════════════════════════════════════════════════════════════════════════════
# QUICK START
# ═══════════════════════════════════════════════════════════════════════════════
#
#   cd /path/to/your/git/repo
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash
#
# ═══════════════════════════════════════════════════════════════════════════════
# USAGE EXAMPLES
# ═══════════════════════════════════════════════════════════════════════════════
#
# Install in current directory:
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash
#
# Install in current directory with verbose output:
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash -s -- -v
#
# Install in current directory, force overwrite, verbose:
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash -s -- -f -v
#
# Install in a specific directory:
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash -s -- /path/to/repo
#
# Install with all options (force + verbose + specific directory):
#   curl -sSL https://raw.githubusercontent.com/viteseodev/viteseo-auto-deploy/main/install.sh | bash -s -- -f -v /path/to/repo
#
# Install from a local clone (offline/testing):
#   ./install.sh --local /path/to/viteseo-auto-deploy /path/to/target-repo
#
# ═══════════════════════════════════════════════════════════════════════════════
# CURL COMMAND BREAKDOWN
# ═══════════════════════════════════════════════════════════════════════════════
#
#   curl -sSL <url> | bash -s -- [options] [target]
#   │    │││         │     │  │
#   │    │││         │     │  └─ End of bash options; everything after goes to script
#   │    │││         │     └──── Read commands from stdin (required for piping)
#   │    │││         └────────── Pipe output to bash
#   │    ││└──────────────────── Follow redirects
#   │    │└───────────────────── Show errors (with -s)
#   │    └────────────────────── Silent mode (no progress bar)
#   └─────────────────────────── Download URL
#
# ═══════════════════════════════════════════════════════════════════════════════
# OPTIONS
# ═══════════════════════════════════════════════════════════════════════════════
#
#   -h, --help       Show help message and exit
#   -f, --force      Overwrite existing files without prompting
#   -q, --quiet      Minimal output (only errors)
#   -v, --verbose    Verbose output for debugging
#   --no-color       Disable colored output
#   --version        Show version information
#   --local <path>   Copy files from local source instead of downloading
#
# ═══════════════════════════════════════════════════════════════════════════════
# WHAT GETS INSTALLED
# ═══════════════════════════════════════════════════════════════════════════════
#
#   .github/workflows/deploy.yml          GitHub Actions workflow
#   .github/workflows/DEPLOYMENT_SETUP.md Detailed setup documentation
#   deploy/pull.sh                        Server-side deployment script
#   deploy/setup-deployment.sh            SSH key generation helper
#   deploy/QUICK_REFERENCE.md             Quick reference guide
#
# ═══════════════════════════════════════════════════════════════════════════════
# REQUIREMENTS
# ═══════════════════════════════════════════════════════════════════════════════
#
#   - Target directory must be a git repository
#   - curl or wget must be installed
#   - Write permissions in target directory
#
# ═══════════════════════════════════════════════════════════════════════════════
# MORE INFORMATION
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Repository: https://github.com/viteseodev/viteseo-auto-deploy
#   Issues:     https://github.com/viteseodev/viteseo-auto-deploy/issues
#
# ═══════════════════════════════════════════════════════════════════════════════

set -o errexit
set -o nounset
set -o pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# GitHub repository containing the deployment files
REPO_OWNER="viteseodev"
REPO_NAME="viteseo-auto-deploy"
REPO_BRANCH="main"
REPO_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

# Files to download
declare -a WORKFLOW_FILES=(
    ".github/workflows/deploy.yml"
    ".github/workflows/DEPLOYMENT_SETUP.md"
)

declare -a DEPLOY_FILES=(
    "deploy/pull.sh"
    "deploy/setup-deployment.sh"
    "deploy/QUICK_REFERENCE.md"
)

# Script version
VERSION="1.0.0"

# Local source directory (if using --local mode)
LOCAL_SOURCE=""

# ═══════════════════════════════════════════════════════════════════════════════
# COLOR CODES
# ═══════════════════════════════════════════════════════════════════════════════

USE_COLOR=true

setup_colors() {
    if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        BOLD=''
        DIM=''
        NC=''
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# OUTPUT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

QUIET=false
VERBOSE=false

print_header() {
    [[ "$QUIET" == true ]] && return
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    [[ "$QUIET" == true ]] && return
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BLUE}ℹ${NC} $1"
}

print_debug() {
    [[ "$VERBOSE" != true ]] && return
    echo -e "${DIM}  [DEBUG] $1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat << EOF
ViteSEO Auto-Deploy Installation Script v${VERSION}

USAGE:
    ${0##*/} [OPTIONS] [TARGET_DIRECTORY]

DESCRIPTION:
    Installs GitHub Actions deployment workflow and scripts into your git repository.
    If TARGET_DIRECTORY is not specified, uses the current directory.

OPTIONS:
    -h, --help       Show this help message and exit
    -f, --force      Overwrite existing files without prompting
    -q, --quiet      Minimal output (only errors)
    -v, --verbose    Verbose output for debugging
    --no-color       Disable colored output
    --version        Show version information
    --local <path>   Copy files from a local source directory instead of downloading

EXAMPLES:
    # Install in current directory
    curl -sSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/install.sh | bash

    # Install with verbose output
    curl -sSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/install.sh | bash -s -- -v

    # Force overwrite existing files with verbose output
    curl -sSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/install.sh | bash -s -- -f -v

    # Install in specific directory
    curl -sSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/install.sh | bash -s -- /path/to/repo

    # All options: force + verbose + specific directory
    curl -sSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/install.sh | bash -s -- -f -v /path/to/repo

    # Install from a local clone (offline/testing)
    ./install.sh --local /path/to/viteseo-auto-deploy /path/to/target-repo

CURL COMMAND BREAKDOWN:
    curl -sSL <url> | bash -s -- [options] [target]
         |||              |  |
         |||              |  +-- End of bash options; rest goes to script
         |||              +---- Read commands from stdin (REQUIRED for piping)
         ||+------------------- Follow redirects
         |+-------------------- Show errors (with -s)
         +--------------------- Silent mode (no progress bar)

WHAT GETS INSTALLED:
    .github/workflows/deploy.yml          - GitHub Actions workflow
    .github/workflows/DEPLOYMENT_SETUP.md - Setup documentation
    deploy/pull.sh                        - Server-side pull script
    deploy/setup-deployment.sh            - SSH key generation helper
    deploy/QUICK_REFERENCE.md             - Quick reference guide

REQUIREMENTS:
    - Git repository (target directory must be a git repo)
    - curl or wget (for downloading files)
    - Write permissions in target directory

For more information, visit:
    https://github.com/${REPO_OWNER}/${REPO_NAME}

EOF
}

show_version() {
    echo "ViteSEO Auto-Deploy Installation Script v${VERSION}"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Download a file using curl or wget
download_file() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_delay=2
    local attempt=0

    print_debug "Downloading: $url -> $output"

    while [[ $attempt -lt $max_retries ]]; do
        attempt=$((attempt + 1))
        
        if command_exists curl; then
            if curl -sSfL --connect-timeout 30 --max-time 60 "$url" -o "$output" 2>/dev/null; then
                return 0
            fi
        elif command_exists wget; then
            if wget -q --timeout=30 "$url" -O "$output" 2>/dev/null; then
                return 0
            fi
        else
            print_error "Neither curl nor wget is available"
            return 1
        fi

        if [[ $attempt -lt $max_retries ]]; then
            print_debug "Download attempt $attempt failed, retrying in ${retry_delay}s..."
            sleep $retry_delay
        fi
    done

    return 1
}

# Check if file exists and handle based on force flag
check_file_exists() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        if [[ "$FORCE" == true ]]; then
            print_debug "Overwriting existing file: $file"
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

validate_prerequisites() {
    print_step "Checking prerequisites..."
    local errors=0

    # Check for curl or wget
    if ! command_exists curl && ! command_exists wget; then
        print_error "Neither 'curl' nor 'wget' is installed"
        print_info "Install one of them:"
        print_info "  Ubuntu/Debian: sudo apt install curl"
        print_info "  CentOS/RHEL:   sudo yum install curl"
        print_info "  macOS:         brew install curl"
        errors=$((errors + 1))
    else
        local downloader="curl"
        command_exists curl || downloader="wget"
        print_success "Download tool available: $downloader"
    fi

    # Check for git
    if ! command_exists git; then
        print_error "'git' is not installed"
        print_info "Install git:"
        print_info "  Ubuntu/Debian: sudo apt install git"
        print_info "  CentOS/RHEL:   sudo yum install git"
        print_info "  macOS:         brew install git"
        errors=$((errors + 1))
    else
        print_success "Git is available: $(git --version 2>/dev/null | head -1)"
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        print_error "Missing $errors required prerequisite(s)"
        return 1
    fi

    return 0
}

validate_git_repository() {
    local target_dir="$1"
    
    print_step "Validating git repository..."

    # Check if directory exists
    if [[ ! -d "$target_dir" ]]; then
        print_error "Directory does not exist: $target_dir"
        print_info "Create the directory first or specify an existing directory"
        return 1
    fi

    # Check if we can access the directory
    if [[ ! -r "$target_dir" ]] || [[ ! -x "$target_dir" ]]; then
        print_error "Cannot access directory: $target_dir"
        print_info "Check that you have read and execute permissions"
        return 1
    fi

    # Check if it's a git repository
    if ! git -C "$target_dir" rev-parse --git-dir &> /dev/null; then
        print_error "Not a git repository: $target_dir"
        echo ""
        print_info "This script must be run inside a git repository."
        print_info "To initialize a new git repository:"
        echo ""
        echo "    cd $target_dir"
        echo "    git init"
        echo "    git remote add origin <your-repository-url>"
        echo ""
        print_info "Or clone an existing repository:"
        echo ""
        echo "    git clone <your-repository-url> $target_dir"
        echo ""
        return 1
    fi

    # Check if we can write to the directory
    if [[ ! -w "$target_dir" ]]; then
        print_error "Cannot write to directory: $target_dir"
        print_info "Check that you have write permissions"
        return 1
    fi

    # Get repository info
    local git_root
    git_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null)
    local current_branch
    current_branch=$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || current_branch="(detached)"
    local remote_url
    remote_url=$(git -C "$target_dir" remote get-url origin 2>/dev/null) || remote_url="(no remote)"

    print_success "Valid git repository detected"
    print_debug "Git root: $git_root"
    print_debug "Current branch: $current_branch"
    print_debug "Remote origin: $remote_url"

    # Warn if installing to a subdirectory of the git repo
    if [[ "$target_dir" != "$git_root" ]]; then
        print_warning "Target directory is not the git root"
        print_info "Git root: $git_root"
        print_info "Target:   $target_dir"
        print_info "Files will be installed relative to: $target_dir"
    fi

    return 0
}

validate_network() {
    # Skip network check if using local source
    if [[ -n "$LOCAL_SOURCE" ]]; then
        print_step "Using local source (skipping network check)..."
        print_success "Local source mode enabled"
        return 0
    fi

    print_step "Checking network connectivity..."

    local test_url="${REPO_BASE_URL}/install.sh"
    
    if command_exists curl; then
        if ! curl -sSf --connect-timeout 10 --max-time 15 -I "$test_url" &> /dev/null; then
            print_error "Cannot reach GitHub"
            print_info "Check your internet connection and try again"
            print_info "Test URL: $test_url"
            print_info ""
            print_info "Alternatively, use --local mode if you have a local copy:"
            print_info "  ./install.sh --local /path/to/viteseo-auto-deploy"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q --timeout=10 --spider "$test_url" &> /dev/null; then
            print_error "Cannot reach GitHub"
            print_info "Check your internet connection and try again"
            print_info "Test URL: $test_url"
            print_info ""
            print_info "Alternatively, use --local mode if you have a local copy:"
            print_info "  ./install.sh --local /path/to/viteseo-auto-deploy"
            return 1
        fi
    fi

    print_success "Network connectivity verified"
    return 0
}

validate_local_source() {
    local source_dir="$1"

    print_step "Validating local source directory..."

    # Check if directory exists
    if [[ ! -d "$source_dir" ]]; then
        print_error "Local source directory does not exist: $source_dir"
        return 1
    fi

    # Check required files exist
    local missing_files=()
    local all_files=("${WORKFLOW_FILES[@]}" "${DEPLOY_FILES[@]}")
    
    for file in "${all_files[@]}"; do
        if [[ ! -f "${source_dir}/${file}" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files in source directory:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    print_success "Local source validated: $source_dir"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALLATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

create_directories() {
    local target_dir="$1"
    
    print_step "Creating directories..."

    local dirs=(
        ".github/workflows"
        "deploy"
    )

    for dir in "${dirs[@]}"; do
        local full_path="${target_dir}/${dir}"
        if [[ ! -d "$full_path" ]]; then
            if mkdir -p "$full_path"; then
                print_success "Created: $dir/"
            else
                print_error "Failed to create directory: $dir"
                return 1
            fi
        else
            print_debug "Directory exists: $dir/"
        fi
    done

    return 0
}

copy_files_local() {
    local target_dir="$1"
    local source_dir="$2"
    local all_files=("${WORKFLOW_FILES[@]}" "${DEPLOY_FILES[@]}")
    local copied=0
    local skipped=0
    local failed=0

    print_step "Copying files from local source..."

    for file in "${all_files[@]}"; do
        local target_path="${target_dir}/${file}"
        local source_path="${source_dir}/${file}"

        # Check if file already exists
        if [[ -f "$target_path" ]]; then
            if [[ "$FORCE" != true ]]; then
                print_warning "File exists (use -f to overwrite): $file"
                skipped=$((skipped + 1))
                continue
            fi
            print_debug "Overwriting: $file"
        fi

        # Copy the file
        if cp "$source_path" "$target_path"; then
            print_success "Copied: $file"
            copied=$((copied + 1))
        else
            print_error "Failed to copy: $file"
            failed=$((failed + 1))
        fi
    done

    echo ""
    print_info "Copy summary: $copied copied, $skipped skipped, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi

    return 0
}

download_files() {
    local target_dir="$1"
    local all_files=("${WORKFLOW_FILES[@]}" "${DEPLOY_FILES[@]}")
    local downloaded=0
    local skipped=0
    local failed=0

    print_step "Downloading files..."

    for file in "${all_files[@]}"; do
        local target_path="${target_dir}/${file}"
        local source_url="${REPO_BASE_URL}/${file}"

        # Check if file already exists
        if [[ -f "$target_path" ]]; then
            if [[ "$FORCE" != true ]]; then
                print_warning "File exists (use -f to overwrite): $file"
                skipped=$((skipped + 1))
                continue
            fi
            print_debug "Overwriting: $file"
        fi

        # Create a temporary file for download
        local temp_file
        temp_file=$(mktemp) || {
            print_error "Failed to create temporary file"
            failed=$((failed + 1))
            continue
        }

        # Download the file
        if download_file "$source_url" "$temp_file"; then
            # Verify the download is not empty
            if [[ ! -s "$temp_file" ]]; then
                print_error "Downloaded file is empty: $file"
                rm -f "$temp_file"
                failed=$((failed + 1))
                continue
            fi

            # Move to target location
            if mv "$temp_file" "$target_path"; then
                print_success "Downloaded: $file"
                downloaded=$((downloaded + 1))
            else
                print_error "Failed to move file: $file"
                rm -f "$temp_file"
                failed=$((failed + 1))
            fi
        else
            print_error "Failed to download: $file"
            print_debug "URL: $source_url"
            rm -f "$temp_file"
            failed=$((failed + 1))
        fi
    done

    echo ""
    print_info "Download summary: $downloaded downloaded, $skipped skipped, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi

    return 0
}

install_files() {
    local target_dir="$1"

    if [[ -n "$LOCAL_SOURCE" ]]; then
        copy_files_local "$target_dir" "$LOCAL_SOURCE"
    else
        download_files "$target_dir"
    fi
}

set_permissions() {
    local target_dir="$1"
    
    print_step "Setting file permissions..."

    # Make shell scripts executable
    local scripts=(
        "deploy/pull.sh"
        "deploy/setup-deployment.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="${target_dir}/${script}"
        if [[ -f "$script_path" ]]; then
            if chmod +x "$script_path"; then
                print_success "Made executable: $script"
            else
                print_warning "Could not set permissions: $script"
            fi
        fi
    done

    return 0
}

update_gitignore() {
    local target_dir="$1"
    local gitignore="${target_dir}/.gitignore"
    local entries_to_add=(
        "logs/"
        "*.log"
    )
    local added=0

    print_step "Updating .gitignore..."

    for entry in "${entries_to_add[@]}"; do
        if [[ -f "$gitignore" ]]; then
            # Check if entry already exists
            if grep -qxF "$entry" "$gitignore" 2>/dev/null; then
                print_debug "Already in .gitignore: $entry"
                continue
            fi
        fi

        # Add the entry
        echo "$entry" >> "$gitignore"
        print_success "Added to .gitignore: $entry"
        added=$((added + 1))
    done

    if [[ $added -eq 0 ]]; then
        print_info "No .gitignore updates needed"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# POST-INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

show_next_steps() {
    local target_dir="$1"
    
    print_header "Installation Complete!"

    echo -e "${BOLD}Files installed:${NC}"
    echo "  .github/workflows/deploy.yml          - GitHub Actions workflow"
    echo "  .github/workflows/DEPLOYMENT_SETUP.md - Detailed setup guide"
    echo "  deploy/pull.sh                        - Server-side deployment script"
    echo "  deploy/setup-deployment.sh            - SSH key generation helper"
    echo "  deploy/QUICK_REFERENCE.md             - Quick reference guide"
    echo ""

    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo "  1. ${CYAN}Configure GitHub Secrets${NC}"
    echo "     Go to: Repository → Settings → Secrets and variables → Actions"
    echo "     Required secrets:"
    echo "       - PROD_BRANCH, STAGING_BRANCH"
    echo "       - PROD_SSH_PRIVATE_KEY, PROD_SSH_HOST, PROD_SSH_PORT, PROD_SSH_USER, PROD_THEME_DIR"
    echo "       - STAGING_SSH_PRIVATE_KEY, STAGING_SSH_HOST, STAGING_SSH_PORT, STAGING_SSH_USER, STAGING_THEME_DIR"
    echo ""
    echo "  2. ${CYAN}Generate SSH keys (optional helper)${NC}"
    echo "     Run: ./deploy/setup-deployment.sh"
    echo ""
    echo "  3. ${CYAN}Set up your server${NC}"
    echo "     - Clone the repository on your server"
    echo "     - Configure git authentication (SSH key or PAT)"
    echo "     - Make pull.sh executable: chmod +x deploy/pull.sh"
    echo ""
    echo "  4. ${CYAN}Commit and push the new files${NC}"
    echo "     git add .github/workflows deploy"
    echo "     git commit -m 'Add auto-deployment workflow'"
    echo "     git push"
    echo ""
    echo "  5. ${CYAN}Test the deployment${NC}"
    echo "     Push to your configured branch to trigger automatic deployment"
    echo ""

    echo -e "${BOLD}Documentation:${NC}"
    echo "  - Quick start:    cat deploy/QUICK_REFERENCE.md"
    echo "  - Full guide:     cat .github/workflows/DEPLOYMENT_SETUP.md"
    echo ""

    echo -e "${GREEN}Happy deploying! 🚀${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    # Default values
    FORCE=false
    TARGET_DIR=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                setup_colors
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-color)
                USE_COLOR=false
                shift
                ;;
            --local)
                if [[ -z "${2:-}" ]]; then
                    print_error "Option --local requires a path argument"
                    exit 1
                fi
                LOCAL_SOURCE="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [[ -z "$TARGET_DIR" ]]; then
                    TARGET_DIR="$1"
                else
                    print_error "Too many arguments"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Initialize colors after parsing --no-color
    setup_colors

    # Default to current directory if not specified
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$(pwd)"
    fi

    # Resolve to absolute path
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
        print_error "Cannot resolve target directory: $TARGET_DIR"
        exit 1
    }

    print_header "ViteSEO Auto-Deploy Installer v${VERSION}"

    print_info "Target directory: $TARGET_DIR"
    [[ "$FORCE" == true ]] && print_info "Force mode: enabled"
    [[ -n "$LOCAL_SOURCE" ]] && print_info "Local source: $LOCAL_SOURCE"
    echo ""

    # Run validations
    if ! validate_prerequisites; then
        echo ""
        print_error "Prerequisite check failed"
        exit 1
    fi
    echo ""

    if ! validate_git_repository "$TARGET_DIR"; then
        echo ""
        print_error "Git repository validation failed"
        exit 1
    fi
    echo ""

    # Validate local source if specified
    if [[ -n "$LOCAL_SOURCE" ]]; then
        # Resolve local source to absolute path
        LOCAL_SOURCE="$(cd "$LOCAL_SOURCE" 2>/dev/null && pwd)" || {
            print_error "Cannot resolve local source directory: $LOCAL_SOURCE"
            exit 1
        }

        if ! validate_local_source "$LOCAL_SOURCE"; then
            echo ""
            print_error "Local source validation failed"
            exit 1
        fi
        echo ""
    fi

    if ! validate_network; then
        echo ""
        print_error "Network check failed"
        exit 1
    fi
    echo ""

    # Perform installation
    if ! create_directories "$TARGET_DIR"; then
        print_error "Failed to create directories"
        exit 1
    fi
    echo ""

    if ! install_files "$TARGET_DIR"; then
        print_error "Some files failed to install"
        print_info "You can try running the script again with --force"
        exit 1
    fi
    echo ""

    if ! set_permissions "$TARGET_DIR"; then
        print_warning "Some permissions could not be set"
    fi
    echo ""

    if ! update_gitignore "$TARGET_DIR"; then
        print_warning "Could not update .gitignore"
    fi
    echo ""

    # Show success message and next steps
    show_next_steps "$TARGET_DIR"

    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

# Handle being piped to bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -p /dev/stdin ]]; then
    main "$@"
fi
