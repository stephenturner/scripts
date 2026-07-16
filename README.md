# scripts

Small command-line utilities I use, plus a few [Raycast](https://www.raycast.com) scripts.

## Utilities

| Script | What it does |
| --- | --- |
| `body` | Runs a command on everything except the first line (e.g. `echo -e "header\n3\n1" \| body sort`) |
| `extract` | Unpacks any archive (zip, tar.gz, rar, 7z, ...) based on its extension |
| `fixms` | Fixes Windows (CRLF) and classic Mac (CR) line endings in place |
| `makeindex.sh` | Prints HTML linking every file under the current directory (`makeindex.sh > index.html`) |
| `path` | Prints the full path of its arguments |
| `rename.pl` | Renames files with a Perl expression (Robin Barker's `rename`) |

Put this directory on your `PATH`, or symlink individual scripts somewhere that already is.

## Raycast scripts

The `raycast/` directory has scripts for shortening DOIs, fetching BibTeX from a DOI, converting Markdown to RTF, and bolding clipboard text with Unicode. They're macOS only. See [raycast/README.md](raycast/README.md) for setup.

## License

MIT, except `rename.pl`, which is under the same terms as Perl itself.
