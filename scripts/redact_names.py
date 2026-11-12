"""Parse a --redact-from names file into cleaned private-repo base names.

Line rules: one name per line; blank lines and whole-line `#`/`//` comments are skipped; a
line's trailing inline "# comment" is dropped; only the repo-name token is kept -- the part
after the last `/` in "owner/repo", and only its first whitespace-delimited word, so a trailing
non-hash annotation like " (note)" does not corrupt the extracted name. Examples:
  "acme/widget-private  # archived"  -> "widget-private"
  "acme/widget-private (note)"       -> "widget-private"
  "bare-private-name"                -> "bare-private-name"

Named with an underscore, not a hyphen, unlike its siblings in this directory: that makes it
importable (`from redact_names import parse_names`) by scripts/test_redact_names.py without
importlib plumbing. It is otherwise run the same way as the other one-shot scripts here.

Usage: python3 -I redact_names.py <names-file>   # prints one cleaned name per line
"""
import sys
from pathlib import Path


def parse_names(lines):
    """Clean an iterable of raw --redact-from lines into repo base names (see module docstring
    for the exact rules). Order and duplicates are preserved; callers that need a set should
    dedupe themselves, same as scrub-titles.py/verify-redaction.py already do downstream."""
    names = []
    for raw in lines:
        s = raw.rstrip("\n").rstrip("\r").lstrip()
        if not s or s.startswith("#") or s.startswith("//"):
            continue
        s = s.split("#", 1)[0].rstrip()  # drop a trailing inline "# comment"
        if not s:
            continue
        words = s.rsplit("/", 1)[-1].split()
        if words:
            names.append(words[0])  # first whitespace-delimited token only
    return names


def main(argv):
    if len(argv) != 2:
        print("usage: redact_names.py <names-file>", file=sys.stderr)
        return 1
    for name in parse_names(Path(argv[1]).read_text().splitlines()):
        print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
