#!/usr/bin/env python3
"""Turns runs of  oVar.Member = value / oVar.Method(...)  lines into Ring brace blocks:

    oInfo = new ProcessStartInfo()            oInfo = new ProcessStartInfo() {
    oInfo.FileName = "cmd"            --->        FileName = "cmd"
    oInfo.Arguments = "/c ver"                    Arguments = "/c ver"
                                              }

A run (2 or more consecutive lines on the same variable) is skipped when a name used on the right side could be taken for a member of the
object inside the braces (any name of the generated classes), so the meaning never changes. Prints what it skipped.
Usage: bracify.py [--dry] file ...
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GEN = os.path.join(ROOT, "libraries", "dotnetlib", "generated")

# every attribute and method name of the generated classes (and of the helper classes): inside braces they win over variables
NAMES = set()
for d, _, fs in os.walk(GEN):
    for f in fs:
        if not f.endswith(".ring"):
            continue
        with open(os.path.join(d, f), encoding="utf-8", errors="replace") as fh:
            for ln in fh:
                m = re.match(r"^\t(?:Func\s+)?([A-Za-z_]\w*)\b", ln)
                if m:
                    NAMES.add(m.group(1).lower())
for extra in ("add", "close", "show", "text", "name", "count", "item", "clear", "left", "right", "top", "bottom", "width", "height", "size",
              "location", "color", "x", "y", "value", "start", "stop", "enabled", "visible", "tag", "font", "image", "id", "length", "type",
              "init", "show", "hide", "focus", "update", "refresh", "run", "line", "pixel", "brush", "pen", "fill", "key"):
    NAMES.add(extra)
KEEP = {"true", "false", "null", "nl", "tab", "string", "number", "list", "self", "this"}

ASSIGN = r"[A-Za-z_][\w.]*\s*(?:\+=|-=|=)\s*.+?"
CALL = r"(?:set\w+Event|clear\w+Event|Controls\.Add|Items\.Add|Nodes\.Add|Children\.Add|Columns\.Add|Rows\.Add|Add|Append)\(.*\)"
STMT = re.compile(r"^(?P<indent>[ 	]*)(?P<var>o[A-Z]\w*)\.(?P<rest>(?:%s|%s))(?P<comment>\s+#.*)?\s*$" % (CALL, ASSIGN))
# a plain constructor call: new Type(...) with nothing after the closing parenthesis (no .Method() chained)
NEW = re.compile(r"^(?P<indent>[ 	]*)(?P<var>o[A-Z]\w*)\s*=\s*(?P<expr>new\s+[A-Za-z_]\w*\s*\((?:[^()]|\([^()]*\))*\))\s*$")


def identifiers(expr):
    expr = re.sub(r'"[^"]*"|\'[^\']*\'', '""', expr)
    out = []
    for m in re.finditer(r"[A-Za-z_]\w*", expr):
        before = expr[:m.start()].rstrip()
        if before.endswith(".") or re.search(r"\bnew$", before):
            continue
        out.append(m.group(0).lower())
    return out


def conflicts(lines, var):
    for ln in lines:
        m = STMT.match(ln)
        rest = m.group("rest")
        member = re.match(r"[A-Za-z_][\w.]*", rest).group(0)
        right = rest[len(member):]
        # a call's arguments or an assigned value
        for ident in identifiers(right):
            if ident in KEEP:
                continue
            if ident in NAMES:
                return ident
    return None


def transform(text, name, report):
    eol = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(eol)
    out = []
    i = 0
    changed = 0
    while i < len(lines):
        m = STMT.match(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        indent, var = m.group("indent"), m.group("var")
        j = i
        while j < len(lines):
            mj = STMT.match(lines[j])
            if not mj or mj.group("indent") != indent or mj.group("var") != var:
                break
            j += 1
        run = lines[i:j]
        if len(run) < 2:
            out.extend(run)
            i = j
            continue
        bad = conflicts(run, var)
        if bad:
            report.append("%s:%d skipped (%s uses '%s')" % (name, i + 1, var, bad))
            out.extend(run)
            i = j
            continue
        body = []
        for ln in run:
            mm = STMT.match(ln)
            body.append(indent + "\t" + mm.group("rest").strip() + (mm.group("comment") or ""))
        prev = out[-1] if out else ""
        pm = NEW.match(prev)
        if pm and pm.group("indent") == indent and pm.group("var") == var:
            out[-1] = prev.rstrip() + " {"
        else:
            out.append(indent + var + " {")
        out.extend(body)
        out.append(indent + "}")
        changed += 1
        i = j
    return eol.join(out), changed


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry" in sys.argv
    report, files_changed, blocks = [], 0, 0
    for f in args:
        with open(f, encoding="utf-8", newline="") as fh:
            text = fh.read()
        new, n = transform(text, os.path.relpath(f, ROOT).replace("\\", "/"), report)
        if n:
            blocks += n
            files_changed += 1
            if not dry:
                with open(f, "w", encoding="utf-8", newline="") as fh:
                    fh.write(new)
    print("%d blocks in %d files%s" % (blocks, files_changed, " (dry run)" if dry else ""))
    for r in report:
        print(r)


if __name__ == "__main__":
    main()
