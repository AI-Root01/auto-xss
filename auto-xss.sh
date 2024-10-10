#!/bin/bash

# Check if all required commands are installed
for cmd in subfinder waybackurls dalfox go; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd is not installed. Please install it before running this script."
        exit 1
    fi
done

# Check if a target domain was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <target_domain> [X-Hackerone header value]"
    exit 1
fi

TARGET=$1
HEADER=""

# Check if X-Hackerone header value is provided
if [ ! -z "$2" ]; then
    HEADER="--header \"X-Hackerone: $2\""
fi

# Create a directory for output files
OUTPUT_DIR="xss_scan_results_${TARGET}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "Starting XSS vulnerability scan for $TARGET"

# Find subdomains and save them to a file
echo "Finding subdomains..."
subfinder -d "$TARGET" -silent | tee "$OUTPUT_DIR/domains.txt"

# Use waybackurls to get archived URLs and save them to a file
echo "Fetching archived URLs..."
cat "$OUTPUT_DIR/domains.txt" | waybackurls | sort -u | tee "$OUTPUT_DIR/waybackurls.txt"

# Analyze URLs for XSS vulnerabilities with dalfox
echo "Scanning for XSS vulnerabilities..."
if [ -z "$HEADER" ]; then
    cat "$OUTPUT_DIR/waybackurls.txt" | dalfox pipe --silence --output "$OUTPUT_DIR/xss_vulnerabilities.txt"
else
    cat "$OUTPUT_DIR/waybackurls.txt" | dalfox pipe --silence $HEADER --output "$OUTPUT_DIR/xss_vulnerabilities.txt"
fi

# Add target name to the report
echo "Target: $TARGET" | cat - "$OUTPUT_DIR/xss_vulnerabilities.txt" > temp && mv temp "$OUTPUT_DIR/xss_vulnerabilities.txt"

echo "Scan complete. Results saved in $OUTPUT_DIR/xss_vulnerabilities.txt"
