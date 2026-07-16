#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Bold Text on Clipboard
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Convert text on clipboard to bold Unicode
# @raycast.author stephen_turner
# @raycast.authorURL https://raycast.com/stephen_turner

# Only works on MacOS
if [ "$(uname)" != "Darwin" ]; then
    echo "macOS only (requires pbpaste/pbcopy)"
    exit 1
fi

# Function to convert text to bold Unicode
convert_to_bold() {
    local input="$1"
    local output=""
    
    # Define the mapping arrays
    bold_lower=(𝗮 𝗯 𝗰 𝗱 𝗲 𝗳 𝗴 𝗵 𝗶 𝗷 𝗸 𝗹 𝗺 𝗻 𝗼 𝗽 𝗾 𝗿 𝘀 𝘁 𝘂 𝘃 𝘄 𝘅 𝘆 𝘇)
    bold_upper=(𝗔 𝗕 𝗖 𝗗 𝗘 𝗙 𝗚 𝗛 𝗜 𝗝 𝗞 𝗟 𝗠 𝗡 𝗢 𝗣 𝗤 𝗥 𝗦 𝗧 𝗨 𝗩 𝗪 𝗫 𝗬 𝗭)
    bold_nums=(𝟬 𝟭 𝟮 𝟯 𝟰 𝟱 𝟲 𝟳 𝟴 𝟵)
    
    # Loop through each character in the input
    for ((i=0; i<${#input}; i++)); do
        char="${input:$i:1}"
        
        if [[ "$char" =~ [a-z] ]]; then
            # Convert lowercase letters
            index=$(printf "%d" "'$char")  # Get ASCII value
            index=$((index - 97))          # 'a' is at index 0 in bold_lower
            output+="${bold_lower[$index]}"
        elif [[ "$char" =~ [A-Z] ]]; then
            # Convert uppercase letters
            index=$(printf "%d" "'$char")  # Get ASCII value
            index=$((index - 65))          # 'A' is at index 0 in bold_upper
            output+="${bold_upper[$index]}"
        elif [[ "$char" =~ [0-9] ]]; then
            # Convert numbers
            index=$((char))                # '0' is at index 0 in bold_nums
            output+="${bold_nums[$index]}"
        else
            # Keep other characters as they are
            output+="$char"
        fi
    done
    
    echo "$output"
}

# Get the text from the clipboard
input_text=$(pbpaste)

# Convert the text to bold
bold_text=$(convert_to_bold "$input_text")

# Copy the bold text back to the clipboard
printf '%s' "$bold_text" | pbcopy

# Notify the user
echo "Converted text copied back to clipboard."