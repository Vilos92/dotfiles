#!/bin/sh

# Format and lint all Python files in the repository using ruff
#
# Usage:
#   ./scripts/ruff.sh        - Check and format (read-only)
#   ./scripts/ruff.sh --fix  - Auto-fix issues and format

set -e

FIX_MODE=false

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--fix]"
            echo "  --fix    Auto-fix fixable linting issues"
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

if [ "$FIX_MODE" = true ]; then
    echo "Auto-fixing linting issues..."
    ruff check --fix .
else
    echo "Checking for linting issues..."
    ruff check .
fi

# Format all Python files using fd (faster than find)
echo "Formatting Python files..."
fd -e py -x ruff format

# Run final check to show any remaining issues
echo "Final check for any remaining issues..."
ruff check .

echo "Ruff formatting and linting complete!"
