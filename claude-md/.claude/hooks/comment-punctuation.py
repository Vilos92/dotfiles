"""PostToolUse hook: warn Claude about semicolons and punctuation dashes in comments.

Claude Code's counterpart to the omp comment-punctuation rules in
claude-md/.claude/rules/. The patterns mirror those rules' `condition` lists,
so change both together. The hook only warns. The edit has already landed.
"""

import json
import os
import re
import sys

PUNCTUATION = r"(;|—|–| -- | - )"

SLASH_PATTERNS = [
    re.compile(r"(^|[^:])//[ \t]*[^\s\-/][^\n]*" + PUNCTUATION, re.MULTILINE),
    re.compile(r"^[ \t]*\*[ \t]+[^\s\-*/][^\n]*" + PUNCTUATION, re.MULTILINE),
    re.compile(r"/\*+[ \t]*[^\s\-*][^\n*]*" + PUNCTUATION, re.MULTILINE),
]
HASH_PATTERNS = [
    re.compile(r"^[ \t]*#[ \t]*[^\s!\-#][^\n]*" + PUNCTUATION, re.MULTILINE),
    re.compile(r"[ \t]#[ \t]+[^\s\-][^\n]*" + PUNCTUATION, re.MULTILINE),
]
SLASH_EXTENSIONS = ("ts", "tsx", "mts", "cts", "js", "jsx", "mjs", "cjs")
HASH_EXTENSIONS = ("sh", "bash", "zsh", "py", "yml", "yaml", "toml")
PATTERNS_BY_EXTENSION = {
    **dict.fromkeys(SLASH_EXTENSIONS, SLASH_PATTERNS),
    **dict.fromkeys(HASH_EXTENSIONS, HASH_PATTERNS),
}
MAX_REPORTED_LINES = 5


def added_text(tool_input):
    """Return only the lines this edit introduced, so untouched context lines don't warn."""
    edits = tool_input.get("edits") or [tool_input]
    added = []
    for edit in edits:
        new = edit.get("new_string") or edit.get("content") or ""
        old_lines = set((edit.get("old_string") or "").splitlines())
        added.extend(line for line in new.splitlines() if line not in old_lines)
    return "\n".join(added)


def main():
    payload = json.load(sys.stdin)
    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or ""
    patterns = PATTERNS_BY_EXTENSION.get(os.path.splitext(path)[1].lstrip("."))
    if not patterns:
        return

    flagged = [
        line.strip()
        for line in added_text(tool_input).splitlines()
        if any(pattern.search(line) for pattern in patterns)
    ]
    if not flagged:
        return

    shown = "\n".join(f"  {line}" for line in flagged[:MAX_REPORTED_LINES])
    message = (
        f"Comment punctuation in {path}. Rewrite these comments without "
        "semicolons or dashes used as punctuation (`;`, `—`, `–`, ` -- `, ` - `). "
        "Split into two sentences, or use a comma or colon. Leave code and "
        f"strings alone.\n{shown}"
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": message,
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
