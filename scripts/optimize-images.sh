#!/bin/bash
#
# Image Optimization Script for DevFest Perros-Guirec
# Converts JPG/PNG images to WebP format for better performance
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
QUALITY=85
WEBP_QUALITY=85
KEEP_ORIGINALS=true
FULL_MODE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Statistics
TOTAL_ORIGINAL_SIZE=0
TOTAL_OPTIMIZED_SIZE=0
FILES_CONVERTED=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_MODE=true
            KEEP_ORIGINALS=false
            shift
            ;;
        --quality)
            WEBP_QUALITY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --full       Replace URLs and remove original files after conversion"
            echo "  --quality N  Set WebP quality (default: 85)"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Convert images, keep originals"
            echo "  $0 --full             # Convert, replace URLs, remove originals"
            echo "  $0 --quality 90       # Convert with higher quality"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v cwebp &> /dev/null; then
        missing+=("cwebp (webp package)")
    fi

    if ! command -v convert &> /dev/null && ! command -v magick &> /dev/null; then
        missing+=("ImageMagick")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing dependencies:${NC}"
        printf '  - %s\n' "${missing[@]}"
        echo ""
        echo "Install with:"
        echo "  sudo apt-get install webp imagemagick"
        exit 1
    fi
}

# Get file size in bytes
get_file_size() {
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null
}

# Format bytes to human readable
human_readable() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc)KB"
    else
        echo "$(echo "scale=1; $bytes/1048576" | bc)MB"
    fi
}

# Convert a single image
convert_image() {
    local input_file="$1"
    local output_file="${input_file%.*}.webp"

    # Skip if WebP already exists and is newer
    if [ -f "$output_file" ] && [ "$output_file" -nt "$input_file" ]; then
        echo -e "  ${YELLOW}Skipping${NC} (up to date): $(basename "$input_file")"
        return 0
    fi

    local original_size=$(get_file_size "$input_file")

    echo -e "  Converting: $(basename "$input_file") → $(basename "$output_file")"

    # Convert to WebP
    if ! cwebp -q "$WEBP_QUALITY" "$input_file" -o "$output_file" 2>/dev/null; then
        echo -e "    ${RED}Failed to convert${NC}: $(basename "$input_file")"
        return 1
    fi

    local new_size=$(get_file_size "$output_file")
    local saved=$((original_size - new_size))
    local percent=$((saved * 100 / original_size))

    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + original_size))
    TOTAL_OPTIMIZED_SIZE=$((TOTAL_OPTIMIZED_SIZE + new_size))
    FILES_CONVERTED=$((FILES_CONVERTED + 1))

    echo -e "    ${GREEN}✓${NC} Saved $(human_readable $saved) (${percent}%)"

    # Remove original if in full mode
    if [ "$FULL_MODE" = true ]; then
        rm "$input_file"
        echo -e "    ${YELLOW}Removed${NC}: $(basename "$input_file")"
    fi
}

# Process directory
process_directory() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        return 0
    fi

    echo ""
    echo "📁 Processing: $dir"

    find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | while IFS= read -r -d '' file; do
        # Skip if already has webp version
        local base="${file%.*}"
        if [ -f "${base}.webp" ] && [ "$KEEP_ORIGINALS" = true ]; then
            continue
        fi
        convert_image "$file"
    done
}

# Replace URLs in markdown/html files
replace_urls() {
    if [ "$FULL_MODE" = false ]; then
        return 0
    fi

    echo ""
    echo "🔗 Replacing URLs in content files..."

    find "$PROJECT_ROOT" -type f \( -name "*.md" -o -name "*.html" -o -name "*.yml" -o -name "*.yaml" \) \
        ! -path "*/_site/*" \
        ! -path "*/.jekyll-cache/*" \
        -exec grep -l '\.jpg\|\.jpeg\|\.png' {} \; | while read -r file; do
        echo "  Updating: $(basename "$file")"
        sed -i 's/\.jpg/.webp/g; s/\.jpeg/.webp/g; s/\.png/.webp/g' "$file"
    done
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Image Optimization for DevFest Perros-Guirec          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Settings:"
    echo "  Quality: $WEBP_QUALITY"
    echo "  Keep originals: $KEEP_ORIGINALS"
    echo "  Full mode: $FULL_MODE"
    echo ""

    check_dependencies

    # Process assets directory
    if [ -d "$PROJECT_ROOT/assets" ]; then
        process_directory "$PROJECT_ROOT/assets"
    fi

    # Process other image locations
    for dir in "$PROJECT_ROOT"/archives/*/; do
        if [ -d "$dir" ]; then
            process_directory "$dir"
        fi
    done

    # Replace URLs if in full mode
    replace_urls

    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                      Summary                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Files converted: $FILES_CONVERTED"

    if [ $FILES_CONVERTED -gt 0 ]; then
        local saved=$((TOTAL_ORIGINAL_SIZE - TOTAL_OPTIMIZED_SIZE))
        local percent=$((saved * 100 / TOTAL_ORIGINAL_SIZE))
        echo "Original size:   $(human_readable $TOTAL_ORIGINAL_SIZE)"
        echo "Optimized size:  $(human_readable $TOTAL_OPTIMIZED_SIZE)"
        echo "Saved:           $(human_readable $saved) (${percent}%)"
    fi

    echo ""
    echo -e "${GREEN}✓ Optimization complete!${NC}"
}

# Run main function
main
