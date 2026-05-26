#!/bin/bash
set -e

# CodeWiki Installer
# Installs CodeWiki CLI tool system-wide using uv

REPO_URL="https://github.com/OwlsAtWork/CodeWiki.git"
INSTALL_DIR="${CODEWIKI_INSTALL_DIR:-$HOME/.codewiki-install}"

print_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║         CodeWiki Installer                ║"
    echo "║   AI-Powered Documentation Generator      ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
}

print_step() {
    echo "→ $1"
}

print_success() {
    echo "✓ $1"
}

print_error() {
    echo "✗ Error: $1" >&2
}

check_dependencies() {
    print_step "Checking dependencies..."

    # Check for Node.js (required for mermaid validation)
    if ! command -v node &> /dev/null; then
        print_error "Node.js is required but not installed."
        echo "  Install Node.js from https://nodejs.org/ or via your package manager:"
        echo "    macOS:  brew install node"
        echo "    Ubuntu: sudo apt install nodejs"
        exit 1
    fi

    print_success "Node.js found: $(node --version)"
}

install_uv() {
    if command -v uv &> /dev/null; then
        print_success "uv already installed: $(uv --version)"
        return 0
    fi

    print_step "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Source the env to get uv in path
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    elif [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &> /dev/null; then
        print_error "Failed to install uv. Please install manually: https://docs.astral.sh/uv/"
        exit 1
    fi

    print_success "uv installed: $(uv --version)"
}

install_codewiki() {
    print_step "Installing CodeWiki..."

    # Install as a global tool using uv
    uv tool install "codewiki @ git+${REPO_URL}" --force

    print_success "CodeWiki installed"
}

install_from_local() {
    print_step "Installing CodeWiki from local directory..."

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Install as a global tool using uv from local path
    uv tool install "${script_dir}" --force

    print_success "CodeWiki installed from local directory"
}

verify_installation() {
    print_step "Verifying installation..."

    # Ensure uv tool bin is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    if command -v codewiki &> /dev/null; then
        print_success "CodeWiki is ready!"
        echo ""
        codewiki --version
    else
        print_error "codewiki command not found in PATH"
        echo ""
        echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo '  export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        echo "Then restart your shell or run:"
        echo '  source ~/.bashrc  # or ~/.zshrc'
        exit 1
    fi
}

print_next_steps() {
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Installation Complete!"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Configure your LLM provider:"
    echo ""
    echo "   # AWS Bedrock (Claude 4.5 Opus)"
    echo "   codewiki config set \\"
    echo "     --provider bedrock \\"
    echo "     --aws-region us-east-1 \\"
    echo "     --main-model us.anthropic.claude-opus-4-5-20251101-v1:0 \\"
    echo "     --cluster-model us.anthropic.claude-opus-4-5-20251101-v1:0"
    echo ""
    echo "   # Or use Anthropic API directly"
    echo "   codewiki config set \\"
    echo "     --provider anthropic \\"
    echo "     --api-key YOUR_API_KEY \\"
    echo "     --main-model claude-sonnet-4-6 \\"
    echo "     --cluster-model claude-sonnet-4-6"
    echo ""
    echo "2. Generate documentation:"
    echo ""
    echo "   cd /path/to/your/repo"
    echo "   codewiki generate"
    echo ""
    echo "For more options: codewiki --help"
    echo ""
}

main() {
    print_banner

    # Parse arguments
    local install_mode="remote"
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local)
                install_mode="local"
                shift
                ;;
            --help|-h)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --local    Install from local directory instead of GitHub"
                echo "  --help     Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    check_dependencies
    install_uv

    if [ "$install_mode" = "local" ]; then
        install_from_local
    else
        install_codewiki
    fi

    verify_installation
    print_next_steps
}

main "$@"
