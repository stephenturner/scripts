#!/bin/sh

# Writes HTML linking every file under the CWD, recursively, to stdout:
# $ makeindex.sh > index.html

echo '<!doctype html><html><head><meta charset="utf-8"></head><body>'
find . -type f -not -path '*/\.*' -not -name "index.html" \
| sed 's/^\.\///' \
| sort \
| perl -ne '
    chomp;
    $href = $_;
    $href =~ s{([^A-Za-z0-9._~/-])}{sprintf("%%%02X", ord($1))}ge;
    $text = $_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    print "<a href=\"$href\">$text</a><br/>\n";
'
echo '</body></html>'
