#!/bin/bash

# Script to check blog post publish queue
# Parses markdown files to determine scheduled vs published posts

set -e

BLOG_DIR="$(dirname "$0")/../blog/content/post"
CURRENT_YEAR=$(date +%Y)
TODAY=$(date +%Y-%m-%d)

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_published=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--published)
            show_published=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -p, --published    Also show already published posts"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Arrays to store post information
declare -a scheduled_posts
declare -a published_posts

# Function to extract date from markdown file
extract_date() {
    local file="$1"
    # Look for date: field in the frontmatter
    grep -m 1 '^date:' "$file" | sed 's/date:[[:space:]]*"\?\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/'
}

# Function to extract title from markdown file
extract_title() {
    local file="$1"
    # Look for title: field in the frontmatter
    grep -m 1 '^title:' "$file" | sed 's/title:[[:space:]]*"\(.*\)"/\1/' | sed "s/title:[[:space:]]*'\(.*\)'/\1/" | sed 's/title:[[:space:]]*//'
}

# Process markdown files
echo -e "${BLUE}Scanning blog posts for year ${CURRENT_YEAR}...${NC}"
echo ""

for file in "${BLOG_DIR}/${CURRENT_YEAR}"-*.md; do
    # Skip if no files match
    [ -e "$file" ] || continue

    post_date=$(extract_date "$file")
    post_title=$(extract_title "$file")
    filename=$(basename "$file")

    # Skip if date couldn't be extracted
    if [ -z "$post_date" ]; then
        continue
    fi

    # Compare dates
    if [[ "$post_date" > "$TODAY" ]] || [[ "$post_date" == "$TODAY" ]]; then
        scheduled_posts+=("$post_date|$filename|$post_title")
    else
        published_posts+=("$post_date|$filename|$post_title")
    fi
done

# Display scheduled posts
echo -e "${YELLOW}=== PUBLICATION QUEUE ===${NC}"
echo ""

if [ ${#scheduled_posts[@]} -eq 0 ]; then
    echo "No posts scheduled for publishing."
else
    # Sort by date
    IFS=$'\n' sorted_scheduled=($(sort <<<"${scheduled_posts[*]}"))
    unset IFS

    for post in "${sorted_scheduled[@]}"; do
        IFS='|' read -r date filename title <<< "$post"
        echo -e "${GREEN}${date}${NC} - ${title}"
        echo "  File: ${filename}"
        echo ""
    done

    echo "Total scheduled: ${#scheduled_posts[@]}"
fi

# Display published posts if requested
if [ "$show_published" = true ]; then
    echo ""
    echo -e "${YELLOW}=== ALREADY PUBLISHED ===${NC}"
    echo ""

    if [ ${#published_posts[@]} -eq 0 ]; then
        echo "No published posts found for ${CURRENT_YEAR}."
    else
        # Sort by date (most recent first)
        IFS=$'\n' sorted_published=($(sort -r <<<"${published_posts[*]}"))
        unset IFS

        for post in "${sorted_published[@]}"; do
            IFS='|' read -r date filename title <<< "$post"
            echo -e "${GREEN}${date}${NC} - ${title}"
            echo "  File: ${filename}"
            echo ""
        done

        echo "Total published: ${#published_posts[@]}"
    fi
fi
