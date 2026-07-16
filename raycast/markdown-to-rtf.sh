#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Markdown to RTF
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Markdown to RTF
# @raycast.author stephen_turner
# @raycast.authorURL https://raycast.com/stephen_turner

# Only works on MacOS
if [ "$(uname)" != "Darwin" ]; then
    echo "macOS only (requires pbpaste/pbcopy)"
    exit 1
fi

pbpaste | pandoc -f markdown -t html | textutil -stdin -format html -convert rtf -stdout | pbcopy
