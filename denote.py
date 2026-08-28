#!/usr/bin/env python3
"""Strip speaker notes from PowerPoint decks.

For each .pptx given, writes a copy named <original>_.pptx with every
speaker note removed. Every other part of the file, including document
metadata, images and the slides themselves, is copied through byte for byte.

A .pptx is a zip archive. Notes live in ppt/notesSlides/notesSlideN.xml, so the
copy drops those parts, the content-type override that declares each one, and
the relationship that points each slide at its notes page. That is the same
thing PowerPoint's own "Remove presentation notes" inspector does.

Usage:
  denote.py deck.pptx
  denote.py *.pptx
  denote.py -f deck.pptx     # overwrite an existing _.pptx
"""

import os
import re
import sys
import zipfile

NOTES_PART = re.compile(r"^ppt/notesSlides/(_rels/)?notesSlide\d+\.xml(\.rels)?$")
SLIDE_RELS = re.compile(r"^ppt/slides/_rels/slide\d+\.xml\.rels$")
CONTENT_TYPES = "[Content_Types].xml"

# <Override PartName="/ppt/notesSlides/notesSlide1.xml" ContentType="..."/>
NOTES_OVERRIDE = re.compile(rb'<Override\s+PartName="/ppt/notesSlides/[^"]*"[^>]*/>')

# <Relationship Id="rId2" Type=".../notesSlide" Target="../notesSlides/..."/>
# Attribute order varies between producers, so match on the type anywhere inside.
NOTES_REL = re.compile(rb'<Relationship(?=[^>]*/relationships/notesSlide")[^>]*/>')

# Text runs, minus the auto slide-number field every notes page carries.
FLD = re.compile(rb"<a:fld\b.*?</a:fld>", re.S)
RUN = re.compile(rb"<a:t>(.*?)</a:t>", re.S)


def notes_text_length(xml):
    """Characters of real note text, ignoring the slide-number placeholder."""
    return sum(len(t.strip()) for t in RUN.findall(FLD.sub(b"", xml)))


def strip(src, dst):
    """Write src to dst without its speaker notes. Returns (slides_with_notes, total)."""
    with zipfile.ZipFile(src) as zin:
        names = zin.namelist()
        notes = [n for n in names if NOTES_PART.match(n)]
        if not notes:
            return 0, 0

        with_text = 0
        for name in notes:
            if name.endswith(".xml") and notes_text_length(zin.read(name)) > 0:
                with_text += 1
        total = sum(1 for n in notes if n.endswith(".xml"))

        with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
            zout.comment = zin.comment
            for item in zin.infolist():
                if NOTES_PART.match(item.filename):
                    continue
                data = zin.read(item.filename)
                if item.filename == CONTENT_TYPES:
                    data = NOTES_OVERRIDE.sub(b"", data)
                elif SLIDE_RELS.match(item.filename):
                    data = NOTES_REL.sub(b"", data)
                # Reuse the original ZipInfo so each entry keeps its timestamp
                # and compression method. (Python's zipfile always rewrites the
                # unix permission bits and the deflate-level flag; PowerPoint
                # reads neither.)
                zout.writestr(item, data)

    return with_text, total


def main(argv):
    force = False
    paths = []
    for arg in argv:
        if arg in ("-f", "--force"):
            force = True
        elif arg in ("-h", "--help"):
            print(__doc__.strip())
            return 0
        else:
            paths.append(arg)

    if not paths:
        sys.stderr.write("usage: denote.py [-f] file.pptx [file.pptx ...]\n")
        return 2

    failed = False
    for path in paths:
        if not path.endswith(".pptx"):
            sys.stderr.write(f"{path}: not a .pptx, skipping\n")
            failed = True
            continue
        if path.endswith("_.pptx"):
            sys.stderr.write(f"{path}: already a denote copy (ends in _.pptx), skipping\n")
            continue

        out = path[: -len(".pptx")] + "_.pptx"
        if os.path.exists(out) and not force:
            sys.stderr.write(f"{out}: already exists, skipping (use -f to overwrite)\n")
            continue

        tmp = out + ".partial"
        try:
            with_text, total = strip(path, tmp)
        except (zipfile.BadZipFile, OSError) as err:
            sys.stderr.write(f"{path}: {err}\n")
            failed = True
            if os.path.exists(tmp):
                os.remove(tmp)
            continue

        if total == 0:
            os.remove(tmp)
            print(f"{path}: no speaker notes, nothing written")
            continue

        os.replace(tmp, out)
        print(f"{path} -> {out} ({with_text} of {total} notes pages had text)")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
