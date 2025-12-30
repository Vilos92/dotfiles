#!/bin/sh

# Format JavaScript/JSX files using Prettier
#
# Usage:
#   ./scripts/prettier.sh        - Check formatting (read-only)
#   ./scripts/prettier.sh --fix  - Auto-fix formatting issues
#   ./scripts/prettier.sh --check - Check only (no formatting, for CI)

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
            echo "  --fix    Auto-fix formatting issues"
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

echo "Running Prettier on JavaScript/JSX files..."

# Show which files will be checked
echo "JavaScript/JSX files to check:"
js_files=$(find . -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.mjs' \) -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | sort)
file_count=$(echo "$js_files" | grep -c . || echo "0")
if [ "$file_count" -gt 0 ] && [ "$file_count" != "0" ]; then
    echo "$js_files" | sed 's/^/  /'
    echo ""
    echo "Found $file_count JavaScript/JSX file(s) to check"
else
    echo "  (no JavaScript/JSX files found)"
fi
echo ""

if [ "$CHECK_MODE" = true ]; then
    echo "Checking formatting (no changes)..."
    bunx prettier --check .
elif [ "$FIX_MODE" = true ]; then
    echo "Formatting files..."
    bunx prettier --write .
else
    echo "Checking formatting (read-only)..."
    bunx prettier --check .
fi

echo "Prettier formatting complete!"

