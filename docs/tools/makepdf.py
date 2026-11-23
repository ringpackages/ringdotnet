#!/usr/bin/env python3
"""Makes one PDF of the documentation: docs/pdf/RingDotNet-documentation.pdf

All the pages of docs/*.html (the pages listed in build.py, in the order of the navigation) are put into one HTML file
(docs/pdf/RingDotNet-documentation.html) and printed by headless Chrome or Edge. The links between pages become links inside the PDF,
and the PDF has bookmarks. The class reference (docs/api/, one page per namespace, thousands of pages in print) is not included.

    python docs/tools/makepdf.py
"""
import html
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
OUT = os.path.join(DOCS, "pdf")
BROWSERS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome", "/usr/bin/chromium", "/usr/bin/chromium-browser",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]
SKIP = {"api"}          # the class reference index only links to the namespace pages


def pages():
    src = open(os.path.join(HERE, "build.py"), encoding="utf-8").read()
    start = src.index("PAGES = [")
    end = src.index("]\n", start)
    return re.findall(r'^\s*\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\)', src[start:end], re.M)


def article_of(name):
    text = open(os.path.join(DOCS, name + ".html"), encoding="utf-8").read()
    a = text.index("<article>") + len("<article>")
    b = text.index("</article>")
    return text[a:b]


def cards_table(m):
    """a list of cards (icon, title, text) is one table in print: the title (a link) and the text in a row"""
    rows = []
    for c in re.finditer(r'<a class="card" href="([^"]*)"[^>]*>(.*?)</a>', m.group(1), re.S):
        t = re.search(r"<b>(.*?)</b>", c.group(2), re.S)
        d = re.search(r"<span>(.*?)</span>", c.group(2), re.S)
        if not t:
            return m.group(0)
        rows.append('<tr><td class="cardname"><a href="%s">%s</a></td><td>%s</td></tr>' % (c.group(1), t.group(1), d.group(1) if d else ""))
    return '<div class="tablewrap"><table class="cardtable"><thead><tr><th>Topic</th><th>Description</th></tr></thead><tbody>%s</tbody></table></div>' % "".join(rows)


def stats_table(m):
    """the row of numbers (a number and its label in a box) is one table in print"""
    items = re.findall(r'<div class="stat"><b>(.*?)</b><span>(.*?)</span></div>', m.group(0), re.S)
    if not items:
        return m.group(0)
    head = "".join("<th>%s</th>" % l for _, l in items)
    row = "".join("<td><b>%s</b></td>" % n for n, _ in items)
    return '<div class="tablewrap"><table class="stattable"><thead><tr>%s</tr></thead><tbody><tr>%s</tr></tbody></table></div>' % (head, row)


def rewrite(body, name, known):
    """ids get the page name in front, links to other pages become links inside the document"""
    body = re.sub(r'\sid="([^"]+)"', lambda m: ' id="p-%s-%s"' % (name, m.group(1)), body)

    def link(m):
        href = m.group(1)
        if href.startswith(("http://", "https://", "mailto:")):
            return m.group(0)
        if href.startswith("#"):
            return 'href="#p-%s-%s"' % (name, href[1:])
        page, _, frag = href.partition("#")
        if page.endswith(".html") and page[:-5] in known:
            target = page[:-5]
            return 'href="#p-%s-%s"' % (target, frag) if frag else 'href="#p-%s"' % target
        return 'data-nolink="1"'            # a page that is not in the PDF (the class reference, source files)
    body = body.replace(' loading="lazy"', "")
    body = re.sub(r'<div class="cards">\s*((?:<a class="card"[^>]*>.*?</a>\s*)+)</div>', cards_table, body, flags=re.S)
    body = re.sub(r'<div class="stats">(?:<div class="stat">.*?</div>)+</div>', stats_table, body, flags=re.S)
    body = re.sub(r'href="([^"]*)"', link, body)
    # a link to a page that is not in the PDF: only its text stays
    body = re.sub(r'<a data-nolink="1"[^>]*>(.*?)</a>', r"\1", body, flags=re.S)
    # a collapsed <details> prints nothing: the source code of the samples (gallery, {{source:}}) is open in the PDF
    body = re.sub(r"<details(?![^>]*\bopen\b)", "<details open", body)
    return body


CSS = """
@page { size: A4; margin: 16mm 14mm 18mm 14mm; }
:root { --side: 0px; }
html { scroll-padding-top: 0; font-size: 15px; }
body { background: #fff; color: #1e2030; font-size: 15px; line-height: 1.55; }
main { display: block !important; margin: 0 !important; padding: 0 !important; max-width: none !important; }
article { max-width: none !important; }
.part { break-before: page; }
.part h1 { break-after: avoid; }
@page cover { size: A4; margin: 0; }
.cover { page: cover; width: 210mm; height: 296.5mm; overflow: hidden; margin: 0; padding: 0; background: #0f0a30; }
.cover svg { display: block; width: 210mm; height: 296.5mm; }
.doc-contents { break-before: page; }
.doc-contents h2 { margin-top: 18px; font-size: 18px; border: 0; }
.doc-contents ol { margin: 4px 0 0 0; padding: 0; list-style: none; columns: 2; column-gap: 24px; }
.doc-contents li { break-inside: avoid; }
.anchor, .copy, .copy-btn, button { display: none !important; }
pre { white-space: pre-wrap !important; word-break: break-word; font-size: 11.5px !important; max-height: none !important; overflow: visible !important; }
pre code { white-space: pre-wrap !important; }
.tablewrap { overflow: visible !important; border: 1px solid #d9dcea; }
table { width: 100% !important; max-width: 100% !important; table-layout: auto; font-size: 12.5px; }
tr { break-inside: avoid; }
thead { display: table-header-group; }
th, td { word-break: normal; overflow-wrap: break-word; min-width: 0; }
td:first-child, th:first-child { hyphens: none; }
td code, th code, td pre { white-space: pre-wrap !important; word-break: normal; overflow-wrap: break-word; }
.gallery { display: block !important; margin: 10px 0 !important; }
.item { display: block !important; break-inside: auto; margin: 0 0 16px; box-shadow: none !important; overflow: visible !important; }
.item .pic { display: block !important; text-align: center; min-height: 0 !important; padding: 12px !important; }
.item .pic img { max-height: 170px !important; width: auto; box-shadow: 0 1px 4px rgba(0,0,0,.25) !important; }
.item .info { padding: 10px 14px 12px; }
.item details { display: block; margin-top: 8px; }
.item details summary { display: none; }
.item .pic, .item .info h3, .item .info p, .item .run { break-inside: avoid; break-after: avoid; }
img { max-width: 100%; break-inside: avoid; }
figure, .shot { break-inside: avoid; }
h1, h2, h3 { break-after: avoid; }
.callout { break-inside: avoid; }
/* the closing Next / Where to go next section is small, so that it stays on the page of the text before it */
article h2[id$='-next'], article h2[id$='-where-to-go-next'] { font-size: 1.15rem; margin: 22px 0 6px; padding-top: 0; }
article h2[id$='-next']::before, article h2[id$='-where-to-go-next']::before { margin-bottom: 10px; }
.code.keep { break-inside: avoid; }
.code .bar { break-after: avoid; }
p, li { orphans: 3; widows: 3; }
.stattable th { font-size: 8.5px !important; letter-spacing: 0 !important; word-break: normal !important; overflow-wrap: normal !important; text-align: center; }
.stattable td { font-size: 17px; text-align: center; }
.cardtable td.cardname { width: 32%; font-weight: 600; }
.cards { display: block !important; }
.cards .card { display: block !important; margin: 2px 0; padding: 2px 0; box-shadow: none !important; border: 0 !important; background: none !important; }
.hero .btns { display: none; }
.pager, footer.site { display: none !important; }
"""


def cover_svg():
    """the cover (docs/tools/cover.svg) with the version of the package and the Ring version it needs"""
    svg = open(os.path.join(HERE, "cover.svg"), encoding="utf-8").read()
    info = open(os.path.join(os.path.dirname(DOCS), "package.ring"), encoding="utf-8").read()
    version = re.search(r':version\s*=\s*"([\d.]+)"', info)
    ring = re.search(r':ringversion\s*=\s*"([\d.]+)"', info)
    if version and ring:
        short = ".".join(version.group(1).split(".")[:2])
        svg = svg.replace("Version 1.0  ·  Ring 1.28", "Version %s  ·  Ring %s" % (short, ring.group(1)))
    return re.sub(r"<\?xml[^>]*\?>", "", svg)


def main():
    os.makedirs(OUT, exist_ok=True)
    allp = [(n, t, s) for n, t, s in pages() if n not in SKIP and os.path.exists(os.path.join(DOCS, n + ".html"))]
    known = {n for n, _, _ in allp}
    parts = []
    toc = []
    section = None
    for name, title, sec in allp:
        if sec != section:
            toc.append("</ol>" if section is not None else "")
            toc.append("<h2>%s</h2><ol>" % html.escape(sec))
            section = sec
        toc.append('<li><a href="#p-%s">%s</a></li>' % (name, html.escape(title)))
        body = rewrite(article_of(name), name, known)
        parts.append('<section class="part" id="p-%s"><article>%s</article></section>' % (name, body))
    toc.append("</ol>")
    doc = """<!doctype html><html lang="en"><head><meta charset="utf-8"><title>RingDotNet documentation</title>
<base href="../"><link rel="stylesheet" href="assets/style.css"><style>%s</style></head><body>
<section class="cover">%s</section>
<section class="doc-contents"><h1>Contents</h1>%s</section>
<main>%s</main>
<script>/* a short code block stays on one page; a long one may be split */
document.querySelectorAll('.code').forEach(function (c) { if (c.offsetHeight < 480) { c.classList.add('keep'); } });</script></body></html>""" % (CSS, cover_svg(), "".join(toc), "".join(parts))
    page = os.path.join(OUT, "RingDotNet-documentation.html")
    open(page, "w", encoding="utf-8").write(doc)
    pdf = os.path.join(OUT, "RingDotNet-documentation.pdf")
    browser = next((b for b in BROWSERS if os.path.exists(b)), None)
    if not browser:
        print("No Chrome or Edge found: open", page, "and print it to PDF")
        return 1
    if os.path.exists(pdf):
        os.remove(pdf)
    cmd = [browser, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--generate-pdf-document-outline",
           "--virtual-time-budget=60000", "--print-to-pdf=" + pdf, "file:///" + page.replace("\\", "/")]
    subprocess.run(cmd, check=False, timeout=900, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.path.exists(pdf):
        print("the documentation -> %s (%.1f MB)" % (pdf, os.path.getsize(pdf) / 1048576))
        return 0
    print("The browser did not write the PDF")
    return 1


if __name__ == "__main__":
    sys.exit(main())
