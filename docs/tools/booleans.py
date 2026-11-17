#!/usr/bin/env python3
"""Writes True / False instead of 1 / 0 where the value is logical:
properties known to be boolean (oForm.MaximizeBox = 0, oBox.Checked = 1 ...) and the expected value of a dnAssert that checks a condition.
Usage: booleans.py [--dry] file ..."""
import os
import re
import sys

BOOL_PROPS = """MaximizeBox MinimizeBox ControlBox ShowInTaskbar TopMost Topmost KeyPreview Checked ReadOnly Enabled Visible Handled SuppressKeyPress
GridLines FullRowSelect UseShellExecute RedirectStandardOutput RedirectStandardError RedirectStandardInput CreateNoWindow Multiline WordWrap
AcceptsReturn AcceptsTab UseSystemPasswordChar CheckOnClick AllowUserToAddRows AllowUserToDeleteRows Selected Cancel AutoSize TabStop
AllowDrop MultiSelect ShowCheckBoxes HideSelection DoubleBuffered Focusable IsEnabled IsChecked IsReadOnly AcceptsReturn
UseVisualStyleBackColor ShowUpDown CheckBoxes LabelEdit Sorted AutoGenerateColumns RowHeadersVisible ColumnHeadersVisible
ShowToolTips ShowFocusCues Capture""".split()
PROP = re.compile(r"(\.(?:%s)\s*(?:\+=|-=|=)\s*)([01])(?![\w.])" % "|".join(BOOL_PROPS))
ASSERT = re.compile(r'^(\s*)dnAssert\((".*?"),(.*),([01])\)(\s*(?:#.*)?)$')
LOGICAL = re.compile(r"(\.(?:%s)$|[<>]=?|\s=\s|\bExists\(|\bIsCompleted\b|\bContains\(|\bStartsWith\(|\bEndsWith\(|\bIsMatch\(|\bTryParse|^\(?is[a-z]+\()" % "|".join(BOOL_PROPS))


def fix_line(line):
    new = PROP.sub(lambda m: m.group(1) + ("True" if m.group(2) == "1" else "False"), line)
    m = ASSERT.match(new)
    if m:
        actual = m.group(3).strip()
        if LOGICAL.search(actual):
            new = '%sdnAssert(%s,%s,%s)%s' % (m.group(1), m.group(2), m.group(3), "True" if m.group(4) == "1" else "False", m.group(5))
    return new


def main():
    dry = "--dry" in sys.argv
    files = [a for a in sys.argv[1:] if not a.startswith("--")]
    changed = lines_changed = 0
    for f in files:
        with open(f, encoding="utf-8", newline="") as fh:
            text = fh.read()
        eol = "\r\n" if "\r\n" in text else "\n"
        out = []
        n = 0
        for ln in text.split(eol):
            nl = fix_line(ln)
            if nl != ln:
                n += 1
            out.append(nl)
        if n:
            changed += 1
            lines_changed += n
            if not dry:
                with open(f, "w", encoding="utf-8", newline="") as fh:
                    fh.write(eol.join(out))
    print("%d lines in %d files%s" % (lines_changed, changed, " (dry run)" if dry else ""))


if __name__ == "__main__":
    main()
