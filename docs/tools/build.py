#!/usr/bin/env python3
"""Builds the RingDotNet documentation: docs/src/*.md --> docs/*.html (plus the gallery pages made from the samples)."""
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
ROOT = os.path.dirname(DOCS)
SRC = os.path.join(DOCS, "src")

# (file, nav title, section)
PAGES = [
    ("index", "Overview", "Start"),
    ("getting-started", "Getting started", "Start"),
    ("how-it-works", "How it works", "Start"),
    ("tutorials", "Tutorials home", "Tutorials: start here"),
    ("tut-concepts", ".NET for Ring programmers", "Tutorials: start here"),
    ("tut-reading-docs", "Reading the .NET docs", "Tutorials: start here"),
    ("tut-01-first-look", "A first look", "Tutorials: The basics"),
    ("tut-02-text", "Working with text", "Tutorials: The basics"),
    ("tut-03-numbers-dates", "Numbers, dates, times", "Tutorials: The basics"),
    ("tut-04-collections", "Collections and LINQ", "Tutorials: The basics"),
    ("tut-05-files", "Files and folders", "Tutorials: The basics"),
    ("tut-06-json-xml", "JSON and XML", "Tutorials: The basics"),
    ("tut-07-errors", "When things go wrong", "Tutorials: The basics"),
    ("tut-08-security", "Hashing and encryption", "Tutorials: The basics"),
    ("tut-09-http", "HTTP", "Tutorials: The basics"),
    ("tut-10-tasks-processes", "Tasks and programs", "Tutorials: The basics"),
    ("tut-29-regex", "Regular expressions", "Tutorials: Text and data formats"),
    ("tut-129-formatting", "Formatting numbers and dates", "Tutorials: Text and data formats"),
    ("tut-52-unicode", "Unicode and encodings", "Tutorials: Text and data formats"),
    ("tut-132-text-encodings", "Text files and encodings", "Tutorials: Text and data formats"),
    ("tut-97-comparers", "Comparing text", "Tutorials: Text and data formats"),
    ("tut-104-text-readers-writers", "Text readers and writers", "Tutorials: Text and data formats"),
    ("tut-86-escaping", "Escaping", "Tutorials: Text and data formats"),
    ("tut-64-urls", "URLs and encodings", "Tutorials: Text and data formats"),
    ("tut-138-base64-hex", "Bytes as text: Base64 and hex", "Tutorials: Text and data formats"),
    ("tut-117-domain-names", "International domain names", "Tutorials: Text and data formats"),
    ("tut-121-mime-types", "MIME types", "Tutorials: Text and data formats"),
    ("tut-100-json-writer", "Writing JSON as a stream", "Tutorials: Text and data formats"),
    ("tut-80-json-nodes", "JSON as a tree", "Tutorials: Text and data formats"),
    ("tut-72-xml", "XML in depth", "Tutorials: Text and data formats"),
    ("tut-77-xslt", "XSLT", "Tutorials: Text and data formats"),
    ("tut-47-markdown", "Markdown to HTML", "Tutorials: Text and data formats"),
    ("tut-66-spelling", "A spell checker", "Tutorials: Text and data formats"),
    ("tut-144-mailmerge", "Mail merge", "Tutorials: Text and data formats"),
    ("tut-152-highlighter", "A syntax highlighter", "Tutorials: Text and data formats"),
    ("tut-101-number-types", "Number types", "Tutorials: Numbers, dates and money"),
    ("tut-126-rounding", "Rounding and the Math class", "Tutorials: Numbers, dates and money"),
    ("tut-90-big-numbers", "Big numbers", "Tutorials: Numbers, dates and money"),
    ("tut-67-bases", "Number systems and big numbers", "Tutorials: Numbers, dates and money"),
    ("tut-57-money", "Money", "Tutorials: Numbers, dates and money"),
    ("tut-99-vectors", "Vectors and matrices", "Tutorials: Numbers, dates and money"),
    ("tut-69-random", "Randomness", "Tutorials: Numbers, dates and money"),
    ("tut-44-statistics", "Statistics, simulation", "Tutorials: Numbers, dates and money"),
    ("tut-103-dates-and-times", "Dates and times", "Tutorials: Numbers, dates and money"),
    ("tut-68-timezones", "Time zones", "Tutorials: Numbers, dates and money"),
    ("tut-43-calendar", "Calendars and dates", "Tutorials: Numbers, dates and money"),
    ("tut-76-calendars", "Other calendars", "Tutorials: Numbers, dates and money"),
    ("tut-135-workdays", "Working days", "Tutorials: Numbers, dates and money"),
    ("tut-33-cultures", "Cultures", "Tutorials: Numbers, dates and money"),
    ("tut-106-arrays", "Arrays", "Tutorials: Collections and algorithms"),
    ("tut-107-sets", "Sets", "Tutorials: Collections and algorithms"),
    ("tut-92-data-structures", "More data structures", "Tutorials: Collections and algorithms"),
    ("tut-89-concurrent-collections", "Collections for many threads", "Tutorials: Collections and algorithms"),
    ("tut-65-enums", "Enums and flags", "Tutorials: Collections and algorithms"),
    ("tut-93-identifiers", "Identifiers and versions", "Tutorials: Collections and algorithms"),
    ("tut-58-undo", "Undo, redo and queues", "Tutorials: Collections and algorithms"),
    ("tut-75-recursion", "Recursion", "Tutorials: Collections and algorithms"),
    ("tut-54-expression", "An expression calculator", "Tutorials: Collections and algorithms"),
    ("tut-59-paths", "Paths and the environment", "Tutorials: Files and streams"),
    ("tut-123-file-info", "File information", "Tutorials: Files and streams"),
    ("tut-124-disks", "Disks and free space", "Tutorials: Files and streams"),
    ("tut-56-streams", "Streams and compression", "Tutorials: Files and streams"),
    ("tut-45-binary", "Binary files", "Tutorials: Files and streams"),
    ("tut-130-random-access", "Random access and file locks", "Tutorials: Files and streams"),
    ("tut-88-compression", "Compression", "Tutorials: Files and streams"),
    ("tut-108-zip-in-memory", "ZIP archives in memory", "Tutorials: Files and streams"),
    ("tut-96-tar", "Tar archives", "Tutorials: Files and streams"),
    ("tut-112-globbing", "File patterns (globbing)", "Tutorials: Files and streams"),
    ("tut-122-watch-folder", "Watching a folder", "Tutorials: Files and streams"),
    ("tut-21-log-analyzer", "A log analyzer", "Tutorials: Files and streams"),
    ("tut-31-duplicates", "Duplicate files", "Tutorials: Files and streams"),
    ("tut-46-backup", "A backup tool", "Tutorials: Files and streams"),
    ("tut-141-renamer", "Rename many files", "Tutorials: Files and streams"),
    ("tut-145-diff", "Compare two files", "Tutorials: Files and streams"),
    ("tut-147-checksums", "Check that files did not change", "Tutorials: Files and streams"),
    ("tut-74-system", "Asking the computer", "Tutorials: Processes and performance"),
    ("tut-50-cli", "A command-line tool", "Tutorials: Processes and performance"),
    ("tut-51-logging", "Logging", "Tutorials: Processes and performance"),
    ("tut-136-tracing", "Tracing", "Tutorials: Processes and performance"),
    ("tut-85-feed-programs", "Working with other programs", "Tutorials: Processes and performance"),
    ("tut-79-processes-talk", "Two programs talking", "Tutorials: Processes and performance"),
    ("tut-82-shared-memory", "Shared memory", "Tutorials: Processes and performance"),
    ("tut-83-tasks-waiting", "Tasks that wait", "Tutorials: Processes and performance"),
    ("tut-71-dispose", "Releasing resources", "Tutorials: Processes and performance"),
    ("tut-53-speed", "Speed: measure first", "Tutorials: Processes and performance"),
    ("tut-98-memory", "Memory and the garbage collector", "Tutorials: Processes and performance"),
    ("tut-118-registry", "The Windows Registry", "Tutorials: Processes and performance"),
    ("tut-81-network-tools", "Network tools", "Tutorials: Networking and the web"),
    ("tut-102-ip-networks", "IP networks", "Tutorials: Networking and the web"),
    ("tut-25-sockets", "Sockets", "Tutorials: Networking and the web"),
    ("tut-91-udp", "UDP", "Tutorials: Networking and the web"),
    ("tut-84-http-client", "HttpClient in depth", "Tutorials: Networking and the web"),
    ("tut-39-rest-client", "A REST client", "Tutorials: Networking and the web"),
    ("tut-16-web-service", "A web service", "Tutorials: Networking and the web"),
    ("tut-26-website", "A small web site", "Tutorials: Networking and the web"),
    ("tut-55-miniweb", "A tiny web framework", "Tutorials: Networking and the web"),
    ("tut-120-routes", "Route templates", "Tutorials: Networking and the web"),
    ("tut-150-shortener", "A link shortener", "Tutorials: Networking and the web"),
    ("tut-94-mail-messages", "E-mail messages", "Tutorials: Networking and the web"),
    ("tut-78-crypto", "Protecting and signing messages", "Tutorials: Security"),
    ("tut-105-signatures", "Digital signatures", "Tutorials: Security"),
    ("tut-116-certificates", "Certificates", "Tutorials: Security"),
    ("tut-113-data-protection", "Protecting data", "Tutorials: Security"),
    ("tut-49-login", "Login and sessions", "Tutorials: Security"),
    ("tut-95-claims", "Identities and claims", "Tutorials: Security"),
    ("tut-114-rate-limiting", "Rate limiting", "Tutorials: Security"),
    ("tut-17-databases", "Databases", "Tutorials: Databases and services"),
    ("tut-30-tables", "Tabular data", "Tutorials: Databases and services"),
    ("tut-73-sql-reports", "Reports with SQL", "Tutorials: Databases and services"),
    ("tut-27-entities", "Entities, migrations", "Tutorials: Databases and services"),
    ("tut-115-access", "Microsoft Access databases", "Tutorials: Databases and services"),
    ("tut-32-settings", "Settings", "Tutorials: Databases and services"),
    ("tut-111-configuration", "Configuration", "Tutorials: Databases and services"),
    ("tut-109-memory-cache", "Caching", "Tutorials: Databases and services"),
    ("tut-110-dependency-injection", "Dependency injection", "Tutorials: Databases and services"),
    ("tut-11-first-window", "Your first window", "Tutorials: Windows Forms"),
    ("tut-12-controls", "Many controls", "Tutorials: Windows Forms"),
    ("tut-128-inputs", "More input controls", "Tutorials: Windows Forms"),
    ("tut-146-keyboard", "The keyboard in a form", "Tutorials: Windows Forms"),
    ("tut-23-layout", "Layout and controls", "Tutorials: Windows Forms"),
    ("tut-134-listview", "A list with columns", "Tutorials: Windows Forms"),
    ("tut-142-grid", "Editing a grid", "Tutorials: Windows Forms"),
    ("tut-13-editor", "A text editor", "Tutorials: Windows Forms"),
    ("tut-133-richtext", "Formatted text", "Tutorials: Windows Forms"),
    ("tut-127-clipboard", "The clipboard", "Tutorials: Windows Forms"),
    ("tut-40-dialog", "Your own dialog", "Tutorials: Windows Forms"),
    ("tut-137-closing", "Closing a window", "Tutorials: Windows Forms"),
    ("tut-149-windows", "More than one window", "Tutorials: Windows Forms"),
    ("tut-41-menus", "Menus, toolbars, shortcuts", "Tutorials: Windows Forms"),
    ("tut-34-timers", "Timers and progress", "Tutorials: Windows Forms"),
    ("tut-14-animation", "Drawing and animation", "Tutorials: Windows Forms"),
    ("tut-139-paint", "Drawing with the mouse", "Tutorials: Windows Forms"),
    ("tut-22-images", "Images", "Tutorials: Windows Forms"),
    ("tut-125-screenshot", "Screens and pictures of windows", "Tutorials: Windows Forms"),
    ("tut-36-chart", "A chart", "Tutorials: Windows Forms"),
    ("tut-42-browser", "A folder browser", "Tutorials: Windows Forms"),
    ("tut-15-wpf", "WPF", "Tutorials: WPF"),
    ("tut-38-wpf-layout", "WPF layout, styles", "Tutorials: WPF"),
    ("tut-131-wpf-binding", "WPF data binding", "Tutorials: WPF"),
    ("tut-140-wpf-menu", "WPF menus and tabs", "Tutorials: WPF"),
    ("tut-148-wpf-lists", "WPF lists and dynamic content", "Tutorials: WPF"),
    ("tut-70-wpf-animation", "WPF animation", "Tutorials: WPF"),
    ("tut-24-todo", "A to-do list", "Tutorials: Projects with windows"),
    ("tut-35-tictactoe", "Tic-Tac-Toe", "Tutorials: Projects with windows"),
    ("tut-143-quiz", "A quiz", "Tutorials: Projects with windows"),
    ("tut-37-runner", "A command runner", "Tutorials: Projects with windows"),
    ("tut-48-addressbook", "An address book", "Tutorials: Projects with windows"),
    ("tut-60-sorting", "Watching sorting algorithms", "Tutorials: Projects with windows"),
    ("tut-61-maze", "A maze", "Tutorials: Projects with windows"),
    ("tut-62-filters", "An image filter lab", "Tutorials: Projects with windows"),
    ("tut-63-chat", "A chat over TCP", "Tutorials: Projects with windows"),
    ("tut-19-callbacks", "Callbacks and events", "Tutorials: Libraries, testing and release"),
    ("tut-20-reflection", "Reflection", "Tutorials: Libraries, testing and release"),
    ("tut-151-inspector", "An object inspector", "Tutorials: Libraries, testing and release"),
    ("tut-87-expressions", "Expression trees", "Tutorials: Libraries, testing and release"),
    ("tut-18-csharp-library", "A C# library", "Tutorials: Libraries, testing and release"),
    ("tut-28-testing", "Testing", "Tutorials: Libraries, testing and release"),
    ("tut-119-distribution", "Giving your program to others", "Tutorials: Libraries, testing and release"),
    ("concepts", "Core concepts", "Guide: the language bridge"),
    ("core-api", "Core functions", "Guide: the language bridge"),
    ("collections-linq", "Collections & LINQ", "Guide: the language bridge"),
    ("callbacks-events", "Callbacks & events", "Guide: the language bridge"),
    ("foundation", "The .NET class library", "Guide: the language bridge"),
    ("winforms", "Windows Forms", "Guide: desktop programs"),
    ("gallery-forms", "Forms samples", "Guide: desktop programs"),
    ("gallery-apps", "Applications", "Guide: desktop programs"),
    ("wpf", "WPF", "Guide: desktop programs"),
    ("gallery-wpf", "WPF samples", "Guide: desktop programs"),
    ("aspnet", "ASP.NET Core", "Guide: web and data"),
    ("ef", "Entity Framework Core", "Guide: web and data"),
    ("ef-reference", "Entity Framework reference", "Guide: web and data"),
    ("own-assemblies", "Your own assemblies", "Guide: extending"),
    ("generator", "Class generator", "Guide: extending"),
    ("testing", "Testing", "Testing and limits"),
    ("gotchas", "Rules and limits", "Testing and limits"),
    ("reference", "Function index", "Reference"),
    ("api", "Class reference", "Reference"),
    ("ring-intro", "Quick introduction to Ring", "Appendix"),
]
TITLES = {p[0]: p[1] for p in PAGES}

KEYWORDS = set("""func function class from if but else elseif ok for in to step next while end return new load try catch done switch on off other
exit loop import package private see give put get call and or not true false null self this this bye again break continue""".split())
CS_KEYWORDS = set("""using namespace class public private protected internal static void return new if else for foreach while var string int long double bool
object null true false override sealed abstract interface struct enum try catch finally throw await async get set in out ref params readonly""".split())


def esc(text):
    return html.escape(text, quote=False)


# ---------------------------------------------------------------- highlighting
TOKEN = re.compile(r"""
    (?P<c>\#[^\n]*|//[^\n]*|/\*.*?\*/)
  | (?P<s>"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'|`[^`\n]*`)
  | (?P<n>\b\d+(?:\.\d+)?\b)
  | (?P<w>[A-Za-z_][A-Za-z_0-9]*)
""", re.X | re.S)


def highlight(code, lang):
    if lang in ("text", "output", "bash", "sh", "console", "xml", "json", "html", "xaml", "ini", "cmd", ""):
        if lang in ("json", "xml", "html", "xaml"):
            return highlight_markup(code)
        return esc(code)
    keywords = CS_KEYWORDS if lang in ("csharp", "cs", "c#") else KEYWORDS
    out, pos = [], 0
    prev_word = ""
    prev_char = ""
    for m in TOKEN.finditer(code):
        out.append(esc(code[pos:m.start()]))
        pos = m.end()
        kind, txt = m.lastgroup, m.group()
        if kind == "c":
            if lang in ("csharp", "cs", "c#") and txt.startswith("#"):
                out.append(esc(txt))
            else:
                out.append('<span class="c">%s</span>' % esc(txt))
        elif kind == "s":
            out.append('<span class="s">%s</span>' % esc(txt))
        elif kind == "n":
            out.append('<span class="n">%s</span>' % esc(txt))
        else:
            low = txt.lower() if lang not in ("csharp", "cs", "c#") else txt
            before = code[:m.start()].rstrip(" \t")[-1:] if m.start() else ""
            after = code[m.end():m.end() + 1]
            if low in keywords:
                out.append('<span class="k">%s</span>' % txt)
            elif re.match(r"^(dn|ui|wpf|web|db)[A-Z]", txt) or (before == "." and after == "(") or (prev_word in ("func", "function") and True):
                out.append('<span class="f">%s</span>' % txt)
            elif prev_word == "new" or (txt[0].isupper() and len(txt) > 2 and after in ("(", " ") and before != "." and lang in ("csharp", "cs", "c#")):
                out.append('<span class="t">%s</span>' % txt)
            else:
                out.append(txt)
            prev_word = low
            continue
        prev_word = ""
    out.append(esc(code[pos:]))
    return "".join(out)


def highlight_markup(code):
    out = esc(code)
    out = re.sub(r'(&lt;/?)([A-Za-z_][\w:.\-]*)', r'\1<span class="k">\2</span>', out)
    out = re.sub(r'([\w:\-]+)(=)(&quot;|")', r'<span class="t">\1</span>\2\3', out)
    out = re.sub(r'(&quot;[^&\n]*&quot;|"[^"\n]*")', r'<span class="s">\1</span>', out)
    return out


def code_block(code, lang="ring", title=""):
    code = code.rstrip("\n")
    label = title or {"ring": "Ring", "output": "Output", "text": "", "bash": "Shell", "csharp": "C#", "xml": "XML", "xaml": "XAML", "json": "JSON", "html": "HTML"}.get(lang, lang)
    cls = "code out" if lang == "output" else "code"
    return ('<div class="%s"><div class="bar"><span class="dots"><i></i><i></i><i></i></span><span>%s</span>'
            '<button class="copy" type="button">Copy</button></div><pre><code>%s</code></pre></div>') % (cls, esc(label), highlight(code, lang))


# ---------------------------------------------------------------- markdown
def slug(text):
    s = re.sub(r"<[^>]+>", "", text)
    s = re.sub(r"[^A-Za-z0-9 \-]", "", s).strip().lower()
    return re.sub(r"\s+", "-", s)


def inline(text):
    parts = re.split(r"(`[^`]+`)", text)
    out = []
    for p in parts:
        if p.startswith("`") and p.endswith("`") and len(p) > 1:
            out.append("<code>%s</code>" % esc(p[1:-1]))
            continue
        p = esc(p)
        p = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", p)
        p = re.sub(r"(?<![\w*])\*([^*\n]+)\*(?![\w*])", r"<em>\1</em>", p)
        p = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", lambda m: '<a href="%s">%s</a>' % (re.sub(r"\.md(#|$)", r".html\1", m.group(2)), m.group(1)), p)
        p = p.replace("&amp;nbsp;", "&nbsp;")
        out.append(p)
    return "".join(out)


def table(lines):
    rows = [[c.strip() for c in re.split(r"(?<!\\)\|", ln.strip().strip("|"))] for ln in lines]
    head, body = rows[0], rows[2:]
    h = "<tr>%s</tr>" % "".join("<th>%s</th>" % inline(c) for c in head)
    b = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % inline(c.replace("\\|", "|")) for c in r) for r in body)
    return '<div class="tablewrap"><table><thead>%s</thead><tbody>%s</tbody></table></div>' % (h, b)


def markdown(text, ctx):
    lines = text.split("\n")
    out, i = [], 0
    heads = []
    while i < len(lines):
        ln = lines[i]
        if not ln.strip():
            i += 1
            continue
        m = re.match(r"^```(\w*)\s*(.*)$", ln)
        if m:
            lang, title = m.group(1) or "text", m.group(2).strip()
            i += 1
            buf = []
            while i < len(lines) and not lines[i].startswith("```"):
                buf.append(lines[i])
                i += 1
            i += 1
            out.append(code_block("\n".join(buf), lang, title))
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", ln)
        if m:
            level, title = len(m.group(1)), m.group(2).strip()
            if level == 1:
                i += 1
                continue
            hid = slug(title)
            heads.append((level, hid, title))
            out.append('<h%d id="%s">%s<a class="anchor" href="#%s">#</a></h%d>' % (level, hid, inline(title), hid, level))
            i += 1
            continue
        if ln.startswith("{{") and ln.rstrip().endswith("}}"):
            out.append(ctx["directive"](ln.strip()[2:-2].strip()))
            i += 1
            continue
        if ln.startswith("<"):
            buf = []
            while i < len(lines) and lines[i].strip():
                buf.append(lines[i])
                i += 1
            out.append("\n".join(buf))
            continue
        m = re.match(r'^!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)\s*$', ln)
        if m:
            cap = m.group(3) or m.group(1)
            out.append('<figure class="shot"><img src="%s" alt="%s" loading="lazy"><figcaption>%s</figcaption></figure>' % (m.group(2), esc(m.group(1)), inline(cap)))
            i += 1
            continue
        if ln.startswith("|"):
            buf = []
            while i < len(lines) and lines[i].startswith("|"):
                buf.append(lines[i])
                i += 1
            out.append(table(buf))
            continue
        if ln.startswith(">"):
            buf = []
            while i < len(lines) and lines[i].startswith(">"):
                buf.append(lines[i][1:].lstrip())
                i += 1
            kind, label = "note", "Note"
            m = re.match(r"^\[!(\w+)\]\s*(.*)$", buf[0])
            if m:
                kind = {"WARNING": "warn", "TIP": "tip", "NOTE": "note"}.get(m.group(1).upper(), "note")
                label = {"warn": "Warning", "tip": "Tip", "note": "Note"}[kind]
                buf[0] = m.group(2)
            body = markdown("\n".join(buf), ctx)[0]
            out.append('<div class="callout %s"><span class="t">%s</span>%s</div>' % (kind, label, body))
            continue
        if re.match(r"^(\s*)([-*]|\d+\.)\s+", ln):
            ordered = bool(re.match(r"^\s*\d+\.", ln))
            items = []
            while i < len(lines) and (re.match(r"^\s*([-*]|\d+\.)\s+", lines[i]) or (lines[i].startswith("  ") and lines[i].strip())):
                if re.match(r"^\s*([-*]|\d+\.)\s+", lines[i]):
                    items.append(re.sub(r"^\s*([-*]|\d+\.)\s+", "", lines[i]))
                else:
                    items[-1] += " " + lines[i].strip()
                i += 1
            tag = "ol" if ordered else "ul"
            out.append("<%s>%s</%s>" % (tag, "".join("<li>%s</li>" % inline(x) for x in items), tag))
            continue
        if ln.strip() == "---":
            out.append("<hr>")
            i += 1
            continue
        buf = []
        while i < len(lines) and lines[i].strip() and not re.match(r"^(```|#{1,4}\s|\||>|!\[|\{\{|<)", lines[i]) and not re.match(r"^\s*([-*]|\d+\.)\s+", lines[i]):
            buf.append(lines[i].strip())
            i += 1
        out.append("<p>%s</p>" % inline(" ".join(buf)))
    return "\n".join(out), heads


# ---------------------------------------------------------------- galleries
def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def first_comment(src):
    lines = []
    for ln in src.split("\n"):
        if ln.startswith("#"):
            lines.append(ln.lstrip("#").strip())
        elif ln.strip() == "" and not lines:
            continue
        else:
            break
    return " ".join(x for x in lines if x)


def pretty(name):
    name = re.sub(r"^\d+_", "", name)
    spaced = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", name.replace("_", " "))
    return spaced[:1].upper() + spaced[1:]


def shot_tag(name, alt):
    path = os.path.join(DOCS, "img", "shots", name)
    if os.path.exists(path):
        return '<img src="img/shots/%s" alt="%s" loading="lazy">' % (name, esc(alt))
    return '<div class="pill">no screenshot</div>'


def gallery(kind):
    items = []
    if kind in ("forms", "wpf"):
        folder = os.path.join(ROOT, "samples", "UsingDotNet", "Forms" if kind == "forms" else "Wpf")
        for f in sorted(os.listdir(folder)):
            if not f.endswith(".ring"):
                continue
            base = f[:-5]
            src = read(os.path.join(folder, f))
            items.append((pretty(base), first_comment(src), "%s-%s.png" % (kind, base), src, "ring samples/UsingDotNet/%s/%s" % ("Forms" if kind == "forms" else "Wpf", f)))
    else:
        folder = os.path.join(ROOT, "samples", "UsingDotNet", "applications")
        for d in sorted(os.listdir(folder)):
            main = os.path.join(folder, d, "main.ring")
            if not os.path.exists(main) or d in ("WebApi",):
                continue
            src = read(main)
            if '"System.Windows' not in src and "dnUseDesktop" not in src:      # a window program: its using block names System.Windows.Forms or WPF
                continue
            items.append((pretty(d), first_comment(src), "app-%s.png" % d, src, "cd samples/UsingDotNet/applications/%s  then  ring main.ring" % d))
    cards = []
    for title, desc, png, src, run in items:
        cards.append(
            '<div class="item" id="%s"><div class="pic">%s</div><div class="info"><h3>%s</h3><p>%s</p><div class="run"><code>%s</code></div>'
            '<details><summary>Source code</summary>%s</details></div></div>'
            % (slug(title), shot_tag(png, title), esc(title), esc(desc) if desc else "&nbsp;", esc(run), code_block(src, "ring", "Ring")))
    return '<div class="gallery">%s</div>' % "".join(cards), len(items)


def directive(cmd):
    if cmd.startswith("gallery:"):
        return gallery(cmd.split(":", 1)[1])[0]
    if cmd.startswith("file:"):
        # {{file:samples/UsingDotNet/Forms/02_button_click.ring}} : a source file as a code block
        rel = cmd.split(":", 1)[1].strip()
        lang = "ring" if rel.endswith(".ring") else ("csharp" if rel.endswith(".cs") else "text")
        return code_block(read(os.path.join(ROOT, rel)), lang, rel)
    if cmd.startswith("source:"):
        rel = cmd.split(":", 1)[1].strip()
        lang = "ring" if rel.endswith(".ring") else ("csharp" if rel.endswith(".cs") else "text")
        return '<details class="src"><summary>%s</summary>%s</details>' % (esc(rel), code_block(read(os.path.join(ROOT, rel)), lang, rel))
    if cmd.startswith("output:"):
        # {{output:samples/UsingDotNet/introduction/test03_collections.ring}} : the real output of a program (run now)
        rel = cmd.split(":", 1)[1].strip()
        parts = rel.split()
        return code_block(run_ring(parts[0], parts[1:]), "output", "Output")
    if cmd.startswith("functions:"):
        return functions(cmd.split(":", 1)[1].strip())
    if cmd.startswith("stats"):
        s = stats()
        cells = [("Namespaces", s["namespaces"]), ("Wrapped classes", s["classes"]), ("Forms samples", s["forms"]), ("WPF samples", s["wpf"]),
                 ("Applications", s["apps"]), ("Test files", s["tests"])]
        return '<div class="stats">%s</div>' % "".join('<div class="stat"><b>%s</b><span>%s</span></div>' % (v, k) for k, v in cells)
    return "<!-- unknown directive %s -->" % esc(cmd)


def run_ring(rel, args):
    import subprocess
    path = os.path.join(ROOT, rel)
    env = dict(os.environ)
    env.pop("RING_HOME", None)
    env["PATH"] = os.path.join(ROOT, "bin") + os.pathsep + env.get("PATH", "")
    cache = os.path.join(HERE, "output-cache")
    os.makedirs(cache, exist_ok=True)
    key = os.path.join(cache, re.sub(r"[^\w]+", "_", rel + " " + " ".join(args)) + ".txt")
    if "--refresh" not in sys.argv and os.path.exists(key):
        return read(key)
    r = subprocess.run([os.environ.get("RING_EXE", "B:/ring/bin/ring.exe"), os.path.basename(path)] + args, cwd=os.path.dirname(path), env=env,
                       capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
    text = (r.stdout + r.stderr).strip().replace(chr(13), "")
    text = text.replace(ROOT.replace("\\", "/"), "<package>").replace(ROOT, "<package>")
    with open(key, "w", encoding="utf-8") as f:
        f.write(text)
    return text


INTERNAL = {"dnPackItem", "dnPack", "dnUnpack", "dnJoin", "dnDispatchCallback", "dnIsIdentifier", "dnFolderOf", "dnShow", "dnTypeCached",
            "dnCreate", "dnWrapObject", "dnLinq", "dnCode", "dnQuerySource", "dnSelected", "webWrapper", "webPlain", "wpfSelfTest", "uiSelfTest"}


def functions(rel):
    """A table of the functions and class methods of a Ring file with the comment above each one."""
    lines = read(os.path.join(ROOT, rel)).split(chr(10))
    rows, comment, cls = [], [], ""
    for ln in lines:
        s = ln.strip()
        m = re.match(r"^class\s+(\w+)", ln, re.I)
        if m:
            cls = m.group(1)
            comment = []
            continue
        if s.startswith("#") and not s.startswith("# ----"):
            comment.append(s.lstrip("#").strip())
            continue
        m = re.match(r"^(\t?)func\s+(\w+)\s*(.*)$", ln, re.I)
        if m:
            name, args = m.group(2), m.group(3).strip()
            top = m.group(1) == ""
            if top:
                cls = ""
            if (top and name in INTERNAL) or (not top and name == "init" and False):
                comment = []
                continue
            if not top and not cls:
                comment = []
                continue
            label = ("%s." % cls if (not top and cls) else "") + name + "(" + re.sub(r"(dn|db|wb|ui|wpf)_", "", args.replace("  ", " ")) + ")"
            rows.append((label, " ".join(comment)))
            comment = []
            continue
        if s:
            comment = []
    body = "".join("<tr><td><code>%s</code></td><td>%s</td></tr>" % (esc(a), inline(b)) for a, b in rows)
    return '<div class="tablewrap"><table><thead><tr><th>Function</th><th>Description</th></tr></thead><tbody>%s</tbody></table></div>' % body


def stats():
    gen = os.path.join(ROOT, "libraries", "dotnetlib", "generated")
    # two files per namespace: <Namespace>.classes.ring has all its classes
    namespaces = [f for f in os.listdir(gen) if f.endswith(".classes.ring")]
    classes = 0
    for f in namespaces:
        with open(os.path.join(gen, f), encoding="utf-8") as fh:
            classes += sum(1 for line in fh if line.startswith("Class "))

    def count(p, ext=".ring"):
        p = os.path.join(ROOT, p)
        return len([f for f in os.listdir(p) if f.endswith(ext)]) if os.path.isdir(p) else 0
    apps = len([d for d in os.listdir(os.path.join(ROOT, "samples", "UsingDotNet", "applications")) if os.path.exists(os.path.join(ROOT, "samples", "UsingDotNet", "applications", d, "main.ring"))])
    tests = len([f for f in os.listdir(os.path.join(ROOT, "samples", "UsingDotNet", "tests")) if f.startswith("test_")])
    return {"namespaces": len(namespaces), "classes": "{:,}".format(classes), "forms": count("samples/UsingDotNet/Forms"), "wpf": count("samples/UsingDotNet/Wpf"), "apps": apps, "tests": tests}


# ---------------------------------------------------------------- templates
def sidebar(current, root=""):
    out, section = [], None
    for name, title, sec in PAGES:
        if sec != section:
            out.append("<h4>%s</h4>" % sec)
            section = sec
        out.append('<a href="%s%s.html"%s>%s</a>' % (root, name, ' class="cur"' if name == current else "", title))
    return "\n".join(out)


def page_html(name, title, lead, body, current, root="", toc=True, heading=None):
    idx = [p[0] for p in PAGES]
    n = idx.index(name) if name in idx else -1
    prev = '<a href="%s.html"><small>Previous</small>%s</a>' % (idx[n - 1], TITLES[idx[n - 1]]) if n > 0 else "<span></span>"
    nxt = '<a class="next" href="%s.html"><small>Next</small>%s</a>' % (idx[n + 1], TITLES[idx[n + 1]]) if n < len(idx) - 1 else "<span></span>"
    head = "" if name == "index" else '<h1>%s</h1>%s' % (esc(heading or title), '<p class="lead">%s</p>' % inline(lead) if lead else "")
    if n < 0 or name == "api":
        prev = nxt = ""
    return """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(title)s · RingDotNet</title>
<meta name="description" content="%(lead)s">
<link rel="stylesheet" href="%(root)sassets/style.css">
<script>window.SITE_ROOT="%(root)s";</script>
<script src="%(root)sassets/search-index.js"></script>
<script src="%(root)sassets/api-index.js"></script>
<script src="%(root)sassets/site.js"></script>
</head>
<body>
<header class="topbar">
	<button class="iconbtn" id="menu" aria-label="Menu">☰</button>
	<a class="brand" href="%(root)sindex.html"><span class="logo">.N</span>RingDotNet<small>for Ring</small></a>
	<span class="spacer"></span>
	<div class="search">
		<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="9" r="6"/><path d="M14 14l4 4"/></svg>
		<input id="q" type="search" placeholder="Search the docs  ( / )" autocomplete="off">
		<div class="results" id="results"></div>
	</div>
	<button class="iconbtn" id="theme" aria-label="Theme">☾</button>
</header>
<nav class="sidebar">
%(sidebar)s
</nav>
<main>
<article>
%(head)s
%(body)s
<div class="pager">%(prev)s%(next)s</div>
<footer class="site">RingDotNet — use .NET classes and methods from Ring programs. Screenshots and output on these pages come from the real samples.</footer>
</article>
%(tocaside)s
</main>
</body>
</html>
""" % {"title": esc(title), "lead": esc(re.sub(r"[`*]", "", lead or "Use .NET classes and methods from Ring programs")), "sidebar": sidebar(current, root), "head": head, "root": root, "tocaside": '<aside class="toc" id="toc"></aside>' if toc else "", "body": body, "prev": prev, "next": nxt}


def parse_front(text):
    meta = {}
    if text.startswith("---"):
        end = text.index("\n---", 3)
        for ln in text[3:end].strip().split("\n"):
            k, _, v = ln.partition(":")
            v = v.strip()
            if len(v) > 1 and v[0] == v[-1] and v[0] in "\"'":
                v = v[1:-1]
            meta[k.strip()] = v
        text = text[end + 4:]
    return meta, text


def plain(text):
    text = re.sub(r'<div class="bar">.*?</div>', "", text, flags=re.S)
    text = re.sub(r"</?span[^>]*>", "", text)
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def main():
    index = []
    count = 0
    for name, title, _ in PAGES:
        if name == "api":
            continue
        path = os.path.join(SRC, name + ".md")
        if not os.path.exists(path):
            print("missing", path)
            continue
        meta, text = parse_front(read(path))
        body, heads = markdown(text, {"directive": directive})
        body = body.replace("@APPS@", str(gallery("apps")[1])).replace("@CLASSES@", stats()["classes"])
        title = meta.get("title", title)
        with open(os.path.join(DOCS, name + ".html"), "w", encoding="utf-8") as f:
            f.write(page_html(name, title, meta.get("lead", ""), body, name))
        # search entries: one per section
        sections = re.split(r'(?=<h2 id=)', body)
        for sec in sections:
            m = re.match(r'<h2 id="([^"]+)">(.*?)<a class="anchor"', sec)
            hid, htitle = (m.group(1), plain(m.group(2))) if m else ("", "")
            index.append({"u": name + ".html" + ("#" + hid if hid else ""), "t": title, "h": htitle, "x": plain(sec)[:600]})
        count += 1
    if os.path.exists(os.path.join(HERE, "api-data", "api.jsonl")):
        sys.path.insert(0, HERE)
        import apipages
        total, nns = apipages.build(page_html, DOCS)
        print("class reference:", total, "classes in", nns, "namespaces")
    with open(os.path.join(DOCS, "assets", "search-index.js"), "w", encoding="utf-8") as f:
        f.write("window.SEARCH_INDEX = " + json.dumps(index) + ";")
    print("built", count, "pages,", len(index), "search entries")


if __name__ == "__main__":
    main()
