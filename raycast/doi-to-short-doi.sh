#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title DOI to Short DOI
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Shorten a DOI via shortdoi.org
# @raycast.author stephenturner
# @raycast.authorURL https://raycast.com/stephen_turner

# Only works on MacOS
if [ "$(uname)" != "Darwin" ]; then
    echo "macOS only (requires pbpaste/pbcopy)"
    exit 1
fi

# Trim whitespace
clip=$(pbpaste | tr -d '[:space:]')

# Match either a doi.org URL or a bare DOI (10.NNNN/...)
if echo "$clip" | grep -Eq '^(https?://)?(dx\.)?doi\.org/10\..+'; then
    doi=$(echo "$clip" | sed -E 's#^(https?://)?(dx\.)?doi\.org/##')
elif echo "$clip" | grep -Eq '^10\.[0-9]+/.+'; then
    doi="$clip"
else
    echo "Clipboard is not a DOI or doi.org link"
    exit 1
fi

# Get the shortDOI
json=$(curl -sfL "https://shortdoi.org/$doi?format=json")
if [ $? -ne 0 ] || [ -z "$json" ]; then
    echo "Failed to fetch shortDOI"
    exit 1
fi

# Extract the ShortDOI field
shortdoi=$(echo "$json" | grep -o '"ShortDOI":"[^"]*"' | sed -E 's/"ShortDOI":"([^"]*)"/\1/')
if [ -z "$shortdoi" ]; then
    echo "Failed to parse shortDOI response"
    exit 1
fi

# Put it on the clipboard
url="https://doi.org/$shortdoi"
printf '%s' "$url" | pbcopy
echo "ShortDOI copied: $url"
