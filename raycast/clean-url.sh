#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clean URL
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Strip tracking params (utm_*, fbclid, etc.) from a URL on the clipboard
# @raycast.author stephen_turner
# @raycast.authorURL https://raycast.com/stephen_turner

# Only works on MacOS
if [ "$(uname)" != "Darwin" ]; then
    echo "macOS only (requires pbpaste/pbcopy)"
    exit 1
fi

# Trim whitespace
url=$(pbpaste | tr -d '[:space:]')

# Must look like an http(s) URL
if ! echo "$url" | grep -Eq '^https?://'; then
    echo "Clipboard is not a URL"
    exit 1
fi

# Split off the query string (and any fragment)
base=${url%%\?*}
frag=""
case "$url" in
    *\?*)
        rest=${url#*\?}
        query=${rest%%#*}
        case "$rest" in *#*) frag="#${rest#*#}";; esac
        ;;
    *)
        # No query string; keep an existing fragment as-is
        printf '%s' "$url" | pbcopy
        echo "URL cleaned: $url"
        exit 0
        ;;
esac

# Tracking params to drop (exact keys or prefixes ending in _)
drop_param() {
    case "$1" in
        utm_*|fbclid|gclid|gbraid|wbraid|dclid|msclkid|yclid|_ga|mc_cid|mc_eid|\
        igshid|igsh|si|ncid|ref|ref_src|ref_url|cmpid|campaign_id|\
        vero_id|vero_conv|oly_enc_id|oly_anon_id|spm|scm|\
        pk_campaign|pk_kwd|piwik_campaign|piwik_kwd|s_cid|elqTrackId|elqTrack)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

# Rebuild the query, keeping only non-tracking params
clean_query=""
IFS='&' read -ra pairs <<< "$query"
for pair in "${pairs[@]}"; do
    [ -z "$pair" ] && continue
    key=${pair%%=*}
    if drop_param "$key"; then
        continue
    fi
    if [ -z "$clean_query" ]; then
        clean_query="$pair"
    else
        clean_query="$clean_query&$pair"
    fi
done

# Reassemble
if [ -n "$clean_query" ]; then
    clean="$base?$clean_query$frag"
else
    clean="$base$frag"
fi

# Copy the cleaned URL back to the clipboard
printf '%s' "$clean" | pbcopy
echo "URL cleaned: $clean"
