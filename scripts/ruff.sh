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
file_count=$(fd -e py 2>/dev/null | wc -l | tr -d ' ') || file_count=$(find . -name '*.py' 2>/dev/null | wc -l | tr -d ' ')
if [ "$file_count" -gt 0 ]; then
    fd -e py 2>/dev/null | sed 's/^/  /' || find . -name '*.py' 2>/dev/null | sed 's/^/  /'
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
    fd -e py -x ruff format --check
else
    echo "Formatting Python files..."
    fd -e py -x ruff format
fi

echo "Final check for any remaining issues..."
ruff check .

echo "Ruff formatting and linting complete!"
