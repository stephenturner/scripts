#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title DOI to BiBTeX
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description DOI to BibTeX
# @raycast.author stephen_turner
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
    url="$clip"
    [[ "$url" =~ ^https?:// ]] || url="https://$url"
elif echo "$clip" | grep -Eq '^10\.[0-9]+/.+'; then
    url="https://doi.org/$clip"
else
    echo "Clipboard is not a DOI or doi.org link"
    exit 1
fi

# Get the BiBTeX
bibtex=$(curl -sfL "$url" -H 'Accept: application/x-bibtex')
if [ $? -ne 0 ] || [ -z "$bibtex" ]; then
    echo "Failed to fetch BibTeX"
    exit 1
fi

# Put it on the clipboard
printf '%s' "$bibtex" | pbcopy
echo "BibTeX copied"