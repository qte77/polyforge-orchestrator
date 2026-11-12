"""Unit tests for redact_names.parse_names, the --redact-from names-file line parser used by
estate-status.sh.

This repo has no existing test harness (no tests/ dir, no test runner wired into the Makefile) --
this is a minimal, standalone unittest module next to the script it tests, per AGENTS.md's
"non-trivial tests only" guidance (this parser has real branching logic, not a declarative
script). Run from the worktree root:

    python3 -m unittest discover -s scripts -p 'test_*.py' -v

or directly: python3 -I scripts/test_redact_names.py -v

Fixtures are synthetic (acme/*, not any real owner or repo name).
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from redact_names import parse_names  # noqa: E402


class ParseNamesTest(unittest.TestCase):
    def test_bare_name(self):
        self.assertEqual(parse_names(["widget-private"]), ["widget-private"])

    def test_owner_slash_name(self):
        self.assertEqual(parse_names(["acme/widget-private"]), ["widget-private"])

    def test_trailing_hash_comment_is_stripped(self):
        # the bug this parser must not have: a trailing "# comment" must not end up inside the
        # extracted name (it previously did, before commit 8449163's fix).
        self.assertEqual(parse_names(["acme/widget-private  # archived"]), ["widget-private"])

    def test_trailing_paren_note_without_hash_is_stripped(self):
        # the bug this test adds: a trailing non-hash annotation must not end up inside the
        # extracted name either (8449163 only stripped "# ..."; this case still broke).
        self.assertEqual(parse_names(["acme/other-private (note)"]), ["other-private"])

    def test_blank_lines_are_skipped(self):
        self.assertEqual(parse_names(["", "   ", "acme/widget-private"]), ["widget-private"])

    def test_whole_line_hash_comment_is_skipped(self):
        self.assertEqual(
            parse_names(["# a header comment", "acme/widget-private"]), ["widget-private"]
        )

    def test_whole_line_slash_slash_comment_is_skipped(self):
        self.assertEqual(
            parse_names(["// a header comment", "acme/widget-private"]), ["widget-private"]
        )

    def test_leading_whitespace_is_trimmed(self):
        self.assertEqual(parse_names(["   acme/widget-private"]), ["widget-private"])

    def test_crlf_line_ending_is_trimmed(self):
        self.assertEqual(parse_names(["acme/widget-private\r"]), ["widget-private"])

    def test_indented_comment_only_line_is_skipped(self):
        self.assertEqual(parse_names(["   # just a comment, no name"]), [])

    def test_trailing_slash_with_no_name_after_comment_strip_is_skipped(self):
        # "owner/" with nothing after the slash once the trailing comment is dropped: empty
        # token, not a false match on the owner segment
        self.assertEqual(parse_names(["acme/   # archived, name removed"]), [])

    def test_multiple_lines_mixed(self):
        lines = [
            "# private repos -- never name in public repos",
            "",
            "acme/widget-private",
            "acme/other-private  # archived",
            "acme/third-private (legacy)",
            "// trailing note, ignored",
            "bare-private",
        ]
        self.assertEqual(
            parse_names(lines),
            ["widget-private", "other-private", "third-private", "bare-private"],
        )


if __name__ == "__main__":
    unittest.main()
