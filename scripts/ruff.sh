#!/bin/sh

# Format and lint all Python files in the repository using ruff
#
# Usage:
#   ./scripts/ruff.sh        - Check and format (read-only)
#   ./scripts/ruff.sh --fix  - Auto-fix issues and format
#   ./scripts/ruff.sh --check - Check only (no formatting, for CI)

set -e

FIX_MODE=false
CHECK_MODE=false

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --check)
            CHECK_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--fix|--check]"
            echo "  --fix    Auto-fix fixable linting issues"
            echo "  --check  Check only (no formatting, for CI)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Running ruff on all Python files..."

# Show which files will be checked
echo "Python files to check:"
# Use find as primary method (more reliable with submodules)
# Exclude Alfred workflow files and other non-repo files
py_files=$(find . -name '*.py' -not -path './.git/*' -not -path '*/__pycache__/*' -not -path './mac-productivity/*' 2>/dev/null | sort)
file_count=$(echo "$py_files" | grep -c . || echo "0")
if [ "$file_count" -gt 0 ] && [ "$file_count" != "0" ]; then
    echo "$py_files" | sed 's/^/  /'
    echo ""
    echo "Found $file_count Python file(s) to check"
else
    echo "  (no Python files found)"
fi
echo ""

if [ "$FIX_MODE" = true ]; then
    echo "Auto-fixing linting issues..."
    ruff check --fix .
else
    echo "Checking for linting issues..."
    ruff check .
fi

if [ "$CHECK_MODE" = true ]; then
    echo "Checking formatting (no changes)..."
    find . -name '*.py' -not -path './.git/*' -not -path '*/__pycache__/*' -not -path './mac-productivity/*' -exec ruff format --check {} +
else
    echo "Formatting Python files..."
    find . -name '*.py' -not -path './.git/*' -not -path '*/__pycache__/*' -not -path './mac-productivity/*' -exec ruff format {} +
fi

echo "Final check for any remaining issues..."
ruff check .

echo "Ruff formatting and linting complete!"
