#!/bin/bash

TOKEN=""
CVE=false
OUTPUT_FILE="output.txt"
DOWNLOAD_DIR="downloads"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token)
            TOKEN="$2"
            shift
            shift
            ;;
        --cves)
            CVE=true
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift
            shift
            ;;
        --download-dir)
            DOWNLOAD_DIR="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$TOKEN" ]]; then
    echo "Error: GitHub token is missing (--token option)"
    exit 1
fi

if [[ -d "$DOWNLOAD_DIR" ]]; then
    echo "Error: Download directory already exists"
    exit 1
fi
mkdir "$DOWNLOAD_DIR"

page=1
while true; do
    ghprs="https://api.github.com/repos/projectdiscovery/nuclei-templates/pulls?state=open&per_page=100&page=$page"
    response=$(curl -s -H "Authorization: Bearer $TOKEN" "$ghprs")
    if [[ "$response" == "[]" ]]; then
        break
    fi
    prs=$(echo "$response" | jq -r '.[].number')
    for pr in $prs; do
        ghfiles="https://api.github.com/repos/projectdiscovery/nuclei-templates/pulls/$pr/files"
        response=$(curl -s -H "Authorization: Bearer $TOKEN" "$ghfiles")
        if [[ "$CVE" == true ]]; then
            files=$(echo "$response" | jq -r '.[] | select(.filename | contains("cves")) | .raw_url')
        else
            files=$(echo "$response" | jq -r '.[].raw_url')
        fi
        echo "$files" >> "$OUTPUT_FILE"
        for url in $files; do
            filename=$(echo "$url" | rev | cut -d'/' -f1 | rev)
            wget -P "$DOWNLOAD_DIR" "$url" -O "$filename"
        done
    done
    page=$((page + 1))
done
