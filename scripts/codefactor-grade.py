"""Print CodeFactor grades for public repos: reads repo names on stdin, prints name<TAB>grade.

Usage: python3 -I codefactor-grade.py <owner>

Fetches only https://www.codefactor.io/repository/github/<owner>/<repo>/badge (GET, no auth).
"""
import re
import sys
import urllib.request

if len(sys.argv) != 2:
    print("usage: codefactor-grade.py <owner>", file=sys.stderr)
    sys.exit(1)

HOST = f"https://www.codefactor.io/repository/github/{sys.argv[1]}/"
for line in sys.stdin:
    name = line.strip()
    if not re.fullmatch(r"[A-Za-z0-9._-]+", name):
        continue
    grade = "unknown"
    try:
        req = urllib.request.Request(HOST + name + "/badge", headers={"User-Agent": "estate-status"})
        # HOST is a fixed "https://" literal above and `name` is regex-validated (no "://"), so the
        # scheme can't be anything but https -- nosec B310 (bandit can't verify that statically).
        with urllib.request.urlopen(req, timeout=20) as r:  # nosec B310
            svg = r.read(20000).decode("utf-8", "replace")
        texts = re.findall(r">([^<>]{1,12})</text>", svg)
        g = [t.strip() for t in texts if re.fullmatch(r"[A-F][+-]?", t.strip())]
        if g:
            grade = g[-1]
    except Exception as e:
        print(f"codefactor-grade: {name}: {e}", file=sys.stderr)
    print(f"{name}\t{grade}", flush=True)
