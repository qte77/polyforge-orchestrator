"""Redact mentions of private-repo names from the last (title) column of a TSV stream.

A PUBLIC repo's own PR/issue title is not masked (see estate-status.sh), but it can still
incidentally name one of the owner's PRIVATE repos as ordinary free text -- that must not surface
in the sweep's output either. This rewrites only the final tab-separated field; other columns
(including the repo-label column) are passed through untouched, so a private name that is also a
substring of a public repo's label (e.g. private "foo" + public "foo-bar") cannot corrupt it.

Usage: python3 -I scrub-titles.py <names-file> < in.tsv > out.tsv
names-file: one private repo base name per line (blank lines ignored).
"""
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("usage: scrub-titles.py <names-file>", file=sys.stderr)
    sys.exit(1)

names = [n.strip() for n in Path(sys.argv[1]).read_text().splitlines() if n.strip()]
names_sorted = sorted(set(names), key=len, reverse=True)
patterns = [re.compile(r"(?<![A-Za-z0-9._-])" + re.escape(n) + r"(?![A-Za-z0-9._-])") for n in names_sorted]

for line in sys.stdin:
    line = line.rstrip("\n")
    if "\t" in line:
        head, _, last = line.rpartition("\t")
        for pat in patterns:
            last = pat.sub("[private repo]", last)
        line = head + "\t" + last
    print(line)
