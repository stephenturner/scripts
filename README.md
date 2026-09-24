# scripts

Small command-line utilities I use, plus a few [Raycast](https://www.raycast.com) scripts.

## Utilities

| Script | What it does |
| --- | --- |
| `body` | Runs a command on everything except the first line (e.g. `echo -e "header\n3\n1" \| body sort`) |
| `copy` | Copies stdin to the system clipboard |
| `denote` | Copies a .pptx to `_.pptx` with all speaker notes stripped, everything else untouched |
| `extract` | Unpacks any archive (zip, tar.gz, rar, 7z, ...) based on its extension |
| `fixms` | Fixes Windows (CRLF) and classic Mac (CR) line endings in place |
| `getpod` | Downloads a video's audio as an mp3 with chapters and cover art, at podcast-grade bitrate |
| `header` | Prints a delimited file's header row, one numbered column per line (`header samples.csv`) |
| `line` | Prints one numbered line of a file or stdin (e.g. `line 3 notes.txt`) |
| `mkcountdown` | Creates a small .mp4 file with a countdown timer ending in an audible beep. |
| `mkindex` | Prints HTML linking every file under the current directory (`mkindex > index.html`) |
| `mksh` | Scaffolds a new executable shell script and opens it in `$EDITOR` |
| `nato` | Spells its arguments out in the NATO phonetic alphabet |
| `pasta` | Prints the system clipboard's contents |
| `pastas` | Watches the clipboard and prints each new value as it's copied |
| `path` | Prints the full path of its arguments |
| `peek` | Lines up a CSV or TSV into readable columns and pages through it with long lines cut off |
| `rename` | Renames files with a Perl expression (Robin Barker's `rename`) |
| `tomp3` | Extracts mono, podcast-quality mp3 audio from video files (`tomp3 *.mp4`) |
| `togif` | Converts a short video into a looping gif at low, medium or high quality (`togif clip.mp4 high`); warns past 10 seconds and refuses past 20 |
| `trash` | Moves files to the trash instead of deleting them permanently |
| `vidstitch` | Joins an intro, main clip and outro with short crossfades and evens out their volume (`vidstitch intro.mp4 talk.mov outro.mp4 final.mp4`) |
| `ytdl` | Downloads video from YouTube (or anywhere yt-dlp supports) as widely playable h264/m4a mp4; `--subs` embeds English subtitles |

Put this directory on your `PATH`, or symlink individual scripts somewhere that already is.

Most of these need nothing beyond what macOS ships with. `getpod` and `ytdl` need [yt-dlp](https://github.com/yt-dlp/yt-dlp), `tomp3`, `togif`, `vidstitch` and `mkcountdown` need [ffmpeg](https://ffmpeg.org), and `extract` calls `unrar`, `7z` or `cabextract` when it runs into those formats.

## Raycast scripts

The `raycast/` directory has scripts for shortening DOIs, fetching BibTeX from a DOI, stripping tracking parameters off a URL, converting Markdown to RTF, bolding clipboard text with Unicode, replacing curly quotes and dashes with ASCII, and counting the words on the clipboard. They're macOS only. See [raycast/README.md](raycast/README.md) for setup.
