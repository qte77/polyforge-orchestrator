"""Verify that none of a set of known-current private-repo names survives, as a whole name, in
any of the given files. Exits 1 and prints only the file and line number (never the matched text
or the name itself) if one does -- this is the hard backstop behind scrub-titles.py: it checks
every column of every output file, not just the title columns scrub-titles.py rewrites, and it is
meant to fail the whole run rather than let a false "no leaks" summary be written.

A hyphen- or dot-joined different name (e.g. a private "foo" next to an unrelated public
"foo-bar") must NOT count as a hit -- the boundary class below treats '.', '-', alnum and '_' as
all part of one "word", matching scrub-titles.py's definition, not grep -w's (which treats
hyphen as a separator and would false-positive on exactly that case).

Usage: python3 -I verify-redaction.py <names-file> <file>...
"""
import re
import sys
from pathlib import Path

if len(sys.argv) < 3:
    print("usage: verify-redaction.py <names-file> <file>...", file=sys.stderr)
    sys.exit(1)

names = [n.strip() for n in Path(sys.argv[1]).read_text().splitlines() if n.strip()]
patterns = [
    re.compile(r"(?<![A-Za-z0-9._-])" + re.escape(n) + r"(?![A-Za-z0-9._-])")
    for n in sorted(set(names), key=len, reverse=True)
]

failed = False
for path in sys.argv[2:]:
    p = Path(path)
    if not p.is_file():
        continue
    text = p.read_text(errors="replace")
    for lineno, line in enumerate(text.splitlines(), 1):
        for pat in patterns:
            if pat.search(line):
                print(f"private-repo name survived redaction: {path} line {lineno}", file=sys.stderr)
                failed = True

sys.exit(1 if failed else 0)
