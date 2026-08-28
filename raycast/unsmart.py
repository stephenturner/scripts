#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Unsmart Text
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Academic

# Documentation:
# @raycast.description Replace curly quotes, dashes, ligatures and other Unicode punctuation on the clipboard with plain ASCII
# @raycast.author stephen_turner
# @raycast.authorURL https://raycast.com/stephen_turner

"""Replace Unicode punctuation on the clipboard with plain ASCII.

Standard library only. The clipboard is decoded and encoded as UTF-8
explicitly rather than through the locale, because Raycast runs script
commands with LC_ALL=UTF-8, which is not a valid locale name.
"""

import os
import subprocess
import sys

# pbpaste and pbcopy transcode the clipboard to whatever encoding the locale
# names. Raycast runs script commands with LC_ALL=UTF-8, which is not a valid
# locale name, so both fall back to Mac OS Roman: smart quotes arrive mangled
# and anything Mac OS Roman lacks arrives as "?". Force a real UTF-8 locale.
CLIPBOARD_ENV = dict(os.environ, LC_ALL="en_US.UTF-8")

REPLACEMENTS = {
    # Quotes, including the prime marks and guillemets PDFs like to use
    "\u2018": "'", "\u2019": "'", "\u201A": "'", "\u201B": "'",
    "\u2032": "'", "\u2039": "'", "\u203A": "'",
    "\u201C": '"', "\u201D": '"', "\u201E": '"', "\u201F": '"',
    "\u2033": '"', "\u00AB": '"', "\u00BB": '"',

    # Dashes. An em dash becomes -- the way pandoc and TeX write one
    "\u2014": "--",
    "\u2013": "-", "\u2010": "-", "\u2011": "-", "\u2012": "-",
    "\u2212": "-",

    # Ellipsis
    "\u2026": "...",

    # Spaces that are not spaces: no-break, en, em, figure, thin, hair,
    # narrow no-break, medium mathematical, ideographic
    "\u00A0": " ", "\u2002": " ", "\u2003": " ", "\u2007": " ",
    "\u2009": " ", "\u200A": " ", "\u202F": " ", "\u205F": " ",
    "\u3000": " ",

    # Invisible characters: soft hyphen, zero-width space, zero-width
    # non-joiner, zero-width joiner, word joiner, byte order mark
    "\u00AD": "", "\u200B": "", "\u200C": "", "\u200D": "",
    "\u2060": "", "\uFEFF": "",

    # Ligatures, which is how "workflow" comes out of a PDF as "work\uFB02ow"
    "\uFB00": "ff", "\uFB01": "fi", "\uFB02": "fl", "\uFB03": "ffi",
    "\uFB04": "ffl",
}


def unsmarten(text):
    """Return (cleaned text, number of characters replaced)."""
    # Line endings first, so a CRLF pair counts as one replacement, not two.
    replaced = text.count("\r\n")
    text = text.replace("\r\n", "\n")
    replaced += text.count("\r")
    text = text.replace("\r", "\n")

    out = []
    for char in text:
        if char in REPLACEMENTS:
            out.append(REPLACEMENTS[char])
            replaced += 1
        else:
            out.append(char)

    return "".join(out), replaced


def main():
    if sys.platform != "darwin":
        print("macOS only (requires pbpaste/pbcopy)")
        return 1

    try:
        clipboard = subprocess.run(
            ["pbpaste"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            env=CLIPBOARD_ENV
        ).stdout
    except OSError as err:
        print("could not read the clipboard: {}".format(err))
        return 1

    if not clipboard:
        print("Clipboard is empty")
        return 0

    text, replaced = unsmarten(clipboard.decode("utf-8", "replace"))

    # Leave the clipboard alone when there's nothing to fix, so its other
    # flavors (RTF, HTML) survive untouched.
    if replaced == 0:
        print("Nothing to unsmarten")
        return 0

    try:
        copy = subprocess.run(["pbcopy"], input=text.encode("utf-8"), env=CLIPBOARD_ENV)
    except OSError as err:
        print("could not write the clipboard: {}".format(err))
        return 1
    if copy.returncode != 0:
        print("pbcopy failed")
        return 1

    print("Unsmartened {} character{}".format(
        replaced, "" if replaced == 1 else "s"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
