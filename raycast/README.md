These are scripts that work well with [Raycast](https://www.raycast.com).

| Script | Raycast command | What it does |
| --- | --- | --- |
| `bold.sh` | Bold Text on Clipboard | Converts clipboard text to bold Unicode characters |
| `clean-url.sh` | Clean URL | Strips tracking params (`utm_*`, `fbclid`, etc.) from a URL on the clipboard |
| `doi-shorten.sh` | DOI to ShortDOI | Turns a DOI or doi.org link on the clipboard into a [shortdoi.org](https://shortdoi.org) link |
| `doi-to-bibtex.sh` | DOI to BiBTeX | Fetches the BibTeX record for a DOI or doi.org link on the clipboard |
| `markdown-to-rtf.sh` | Markdown to RTF | Renders clipboard Markdown as RTF, ready to paste into Word or email |

Each one reads the clipboard and writes its result back to the clipboard. All are macOS only (`pbpaste`/`pbcopy`), and `markdown-to-rtf.sh` also needs [pandoc](https://pandoc.org).

## Setup

Open Raycast settings (`Cmd+,`), under **Scripts**, and add this directory.

You can then invoke a script by its Raycast command above, or assign it a keyboard shortcut.
