# scripts

Small command-line utilities I use, plus a few [Raycast](https://www.raycast.com) scripts.

## Utilities

| Script | What it does |
| --- | --- |
| `body` | Runs a command on everything except the first line (e.g. `echo -e "header\n3\n1" \| body sort`) |
| `copy` | Copies stdin to the system clipboard |
| `extract` | Unpacks any archive (zip, tar.gz, rar, 7z, ...) based on its extension |
| `fixms` | Fixes Windows (CRLF) and classic Mac (CR) line endings in place |
| `make-html-index.sh` | Prints HTML linking every file under the current directory (`make-html-index.sh > index.html`) |
| `make-countdown-timer.sh` | Creates a small .mp4 file with a countdown timer ending in an audible beep. |
| `mksh` | Scaffolds a new executable shell script and opens it in `$EDITOR` |
| `pasta` | Prints the system clipboard's contents |
| `pastas` | Watches the clipboard and prints each new value as it's copied |
| `path` | Prints the full path of its arguments |
| `rename` | Renames files with a Perl expression (Robin Barker's `rename`) |
| `trash` | Moves files to the trash instead of deleting them permanently |

Put this directory on your `PATH`, or symlink individual scripts somewhere that already is.

## Raycast scripts

The `raycast/` directory has scripts for shortening DOIs, fetching BibTeX from a DOI, converting Markdown to RTF, and bolding clipboard text with Unicode. They're macOS only. See [raycast/README.md](raycast/README.md) for setup.
