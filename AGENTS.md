# AGENTS.md

Single-file command-line utilities, plus Raycast script commands in `raycast/`. There is no build step, no test suite, and no package manifest. Each script stands alone and is meant to be readable in one screen.

## Adding a utility

Run `mksh <name>` to scaffold one. It writes the house preamble and opens `$EDITOR`:

```bash
#!/usr/bin/env bash
set -e
set -u
set -o pipefail
```

Top-level utilities have no file extension (`body`, `peek`, `trash`), Python ones included. The name is the command, so it should not advertise what the script is written in. Scripts that create a file take the `mk` prefix: `mksh`, `mkindex`, `mkcountdown`. Make the file executable.

Follow the preamble with a comment block saying what the script does and showing one invocation:

```bash
# Prints a single numbered line from its input. E.g.:
# $ line 3 notes.txt
```

Scripts that take arguments define `help` and `usage`, then print both and exit 0 when called with none. See `tomp3` or `line`.

Guard macOS-only scripts on `uname`, the way `trash` does.

## Python

Standard library only. Nothing here should need `pip install`. Shebang is `#!/usr/bin/env python3`. `denote` is the model: a couple of pure functions that take and return values, a thin `main()`, and `if __name__ == "__main__"` at the bottom so the logic can be exercised without running the script. With no `.py` extension, load it with `importlib.util.spec_from_file_location` rather than a plain import.

## Raycast scripts

They live in `raycast/` and keep the metadata comment block verbatim, including `@raycast.icon 🤖`, `@raycast.packageName Academic`, and the `stephen_turner` author fields.

Pick the mode deliberately. Use `silent` when the result goes to the clipboard and there is nothing to read. Use `compact` when the output itself is the point, like `word-count.py`.

Raycast runs script commands with `LC_ALL=UTF-8`. That is not a valid locale name, so anything locale-aware falls back to the C locale. Two consequences, both of which have bitten these scripts:

- `pbpaste` and `pbcopy` transcode to Mac OS Roman instead of UTF-8. Smart quotes arrive as single bytes that are not valid UTF-8, and characters Mac OS Roman lacks (the ﬄ ligature, the ′ prime) are replaced by `?` and lost for good. Pass a real locale to those subprocesses: `env=dict(os.environ, LC_ALL="en_US.UTF-8")`.
- `perl -CSD` prints "Setting locale failed" to stderr, which Raycast surfaces instead of the script's own output.

Both were the actual cause of bugs that looked like logic errors. Check the encoding before suspecting the code.

## Documentation

Every script gets a row in `README.md`, and every Raycast script also gets one in `raycast/README.md`. Keep the dependency paragraph in `README.md` accurate when adding a script that shells out to something macOS does not ship.

Verify a claim before writing it down. Comment examples are not dependencies, and a shebang is not always what the last version of the file used.

When writing prose, no em dashes and no filler. Keep each paragraph and list item on a single line rather than hard-wrapping.
