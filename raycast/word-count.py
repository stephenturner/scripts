#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Word Count
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Count the words and characters of the text on the clipboard
# @raycast.author stephen_turner
# @raycast.authorURL https://raycast.com/stephen_turner

"""Report the word and character count of the clipboard.

Standard library only. The clipboard is decoded as UTF-8 explicitly rather
than through the locale, because Raycast runs script commands with
LC_CTYPE=UTF-8, which is not a real locale name.
"""

import os
import subprocess
import sys


# pbpaste and pbcopy transcode the clipboard to whatever encoding the locale
# names. Raycast runs script commands with LC_ALL=UTF-8, which is not a valid
# locale name, so both fall back to Mac OS Roman: smart quotes arrive mangled
# and anything Mac OS Roman lacks arrives as "?". Force a real UTF-8 locale.
CLIPBOARD_ENV = dict(os.environ, LC_ALL="en_US.UTF-8")

def summarize(text):
    """Return the count line for text, or None if there's nothing to count."""
    text = text.rstrip()
    if not text:
        return None

    words = len(text.split())
    chars = len(text)
    bare = len("".join(text.split()))

    return "{:,} word{}, {:,} character{} ({:,} without spaces)".format(
        words, "" if words == 1 else "s",
        chars, "" if chars == 1 else "s",
        bare,
    )


def main():
    if sys.platform != "darwin":
        print("macOS only (requires pbpaste)")
        return 1

    try:
        clipboard = subprocess.run(
            ["pbpaste"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            env=CLIPBOARD_ENV
        ).stdout
    except OSError as err:
        print("could not read the clipboard: {}".format(err))
        return 1

    # Not text/utf-8? Show the replacement chars rather than dying on decode.
    line = summarize(clipboard.decode("utf-8", "replace"))
    print(line if line else "Clipboard is empty")
    return 0


if __name__ == "__main__":
    sys.exit(main())
