# scripts

Small command-line utilities I use, plus a few [Raycast](https://www.raycast.com) scripts.

## Utilities

| Script | What it does |
| --- | --- |
| `body` | Runs a command on everything except the first line (e.g. `echo -e "header\n3\n1" \| body sort`) |
| `copy` | Copies stdin to the system clipboard |
| `denote.py` | Copies a .pptx to `_.pptx` with all speaker notes stripped, everything else untouched |
| `extract` | Unpacks any archive (zip, tar.gz, rar, 7z, ...) based on its extension |
| `fixms` | Fixes Windows (CRLF) and classic Mac (CR) line endings in place |
| `getpod` | Downloads a video's audio as an mp3 with chapters and cover art, at podcast-grade bitrate |
| `header` | Prints a delimited file's header row, one numbered column per line (`header samples.csv`) |
| `line` | Prints one numbered line of a file or stdin (e.g. `line 3 notes.txt`) |
| `make-html-index.sh` | Prints HTML linking every file under the current directory (`make-html-index.sh > index.html`) |
| `make-countdown-timer.sh` | Creates a small .mp4 file with a countdown timer ending in an audible beep. |
| `mksh` | Scaffolds a new executable shell script and opens it in `$EDITOR` |
| `nato` | Spells its arguments out in the NATO phonetic alphabet |
| `pasta` | Prints the system clipboard's contents |
| `pastas` | Watches the clipboard and prints each new value as it's copied |
| `path` | Prints the full path of its arguments |
| `peek` | Lines up a CSV or TSV into readable columns and pages through it with long lines cut off |
| `rename` | Renames files with a Perl expression (Robin Barker's `rename`) |
| `tomp3` | Extracts mono, podcast-quality mp3 audio from video files (`tomp3 *.mp4`) |
| `trash` | Moves files to the trash instead of deleting them permanently |
| `ytdl` | Downloads video from YouTube (or anywhere yt-dlp supports) as widely playable h264/m4a mp4; `--subs` embeds English subtitles |

Put this directory on your `PATH`, or symlink individual scripts somewhere that already is.

## Raycast scripts

The `raycast/` directory has scripts for shortening DOIs, fetching BibTeX from a DOI, stripping tracking parameters off a URL, converting Markdown to RTF, bolding clipboard text with Unicode, replacing curly quotes and dashes with ASCII, and counting the words on the clipboard. They're macOS only. See [raycast/README.md](raycast/README.md) for setup.
