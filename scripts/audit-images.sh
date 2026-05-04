#!/bin/bash
#
# Image Audit Script for DevFest Perros-Guirec
# Checks for broken image references and optimization opportunities
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Counters
BROKEN_REFERENCES=0
MISSING_WEBP=0
LARGE_IMAGES=0

# Size threshold (500KB)
SIZE_THRESHOLD=512000

echo "╔════════════════════════════════════════════════════════════╗"
echo "║            Image Reference Audit Report                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check for referenced images that don't exist
check_broken_references() {
    echo "🔍 Checking for broken image references..."
    echo ""

    # Find all image references in markdown, HTML, and YAML files
    grep -rE '\.(jpg|jpeg|png|webp|gif)' "$PROJECT_ROOT" \
        --include="*.md" \
        --include="*.html" \
        --include="*.yml" \
        --include="*.yaml" \
        -o 2>/dev/null | \
        grep -v "_site" | \
        grep -v ".jekyll-cache" | \
        sort -u > /tmp/image_refs.txt || true

    while IFS=: read -r file ref; do
        # Clean up the reference
        ref=$(echo "$ref" | sed 's/.*["'\''"]//g; s/).*//g; s/,.*//g')

        # Skip external URLs
        if [[ "$ref" == http* ]]; then
            continue
        fi

        # Resolve relative path
        local dir=$(dirname "$file")
        local fullpath

        if [[ "$ref" == /* ]]; then
            fullpath="$PROJECT_ROOT/$ref"
        else
            fullpath="$dir/$ref"
        fi

        # Normalize path
        fullpath=$(cd "$(dirname "$fullpath")" 2>/dev/null && pwd)/$(basename "$fullpath") 2>/dev/null || true

        if [ ! -f "$fullpath" ]; then
            echo -e "  ${RED}✗ Missing${NC}: $ref"
            echo "    Referenced in: $file"
            BROKEN_REFERENCES=$((BROKEN_REFERENCES + 1))
        fi
    done < /tmp/image_refs.txt

    if [ $BROKEN_REFERENCES -eq 0 ]; then
        echo -e "  ${GREEN}✓ No broken references found${NC}"
    fi
    echo ""
}

# Find images without WebP versions
check_webp_opportunities() {
    echo "🔄 Checking for WebP optimization opportunities..."
    echo ""

    find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) 2>/dev/null | while read -r file; do
        local webp_version="${file%.*}.webp"
        if [ ! -f "$webp_version" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            local size_mb=$(echo "scale=2; $size/1048576" | bc)
            echo -e "  ${YELLOW}⚠ No WebP${NC}: $(basename "$file") (${size_mb}MB)"
            MISSING_WEBP=$((MISSING_WEBP + 1))
        fi
    done

    if [ $MISSING_WEBP -eq 0 ]; then
        echo -e "  ${GREEN}✓ All images have WebP versions${NC}"
    fi
    echo ""
}

# Find large images
check_large_images() {
    echo "📦 Checking for large unoptimized images..."
    echo ""

    find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -size +500k 2>/dev/null | while read -r file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        local size_mb=$(echo "scale=2; $size/1048576" | bc)
        echo -e "  ${YELLOW}⚠ Large${NC}: $(basename "$file") (${size_mb}MB)"
        LARGE_IMAGES=$((LARGE_IMAGES + 1))
    done

    if [ $LARGE_IMAGES -eq 0 ]; then
        echo -e "  ${GREEN}✓ No oversized images found${NC}"
    fi
    echo ""
}

# Generate statistics
generate_stats() {
    echo "📊 Image Statistics"
    echo ""

    local total_images=$(find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) 2>/dev/null | wc -l)
    local webp_images=$(find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f -name "*.webp" 2>/dev/null | wc -l)
    local total_size=$(find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) -exec stat -f%z {} + 2>/dev/null | awk '{sum+=$1} END {print sum}' || \
                         find "$PROJECT_ROOT/assets" "$PROJECT_ROOT/archives" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {print sum}')

    echo "  Total images: $total_images"
    echo "  WebP images:  $webp_images"
    echo "  WebP ratio:   $(echo "scale=1; $webp_images * 100 / $total_images" | bc)%"

    if [ -n "$total_size" ]; then
        local size_mb=$(echo "scale=2; $total_size/1048576" | bc)
        echo "  Total size:   ${size_mb}MB"
    fi
    echo ""
}

# Main
main() {
    check_broken_references
    check_webp_opportunities
    check_large_images
    generate_stats

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                       Summary                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Broken references: $BROKEN_REFERENCES"
    echo "Missing WebP:      $MISSING_WEBP"
    echo "Large images:      $LARGE_IMAGES"
    echo ""

    if [ $BROKEN_REFERENCES -eq 0 ] && [ $MISSING_WEBP -eq 0 ] && [ $LARGE_IMAGES -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Some issues found. Run ./scripts/optimize-images.sh to fix.${NC}"
        return 1
    fi
}

main
