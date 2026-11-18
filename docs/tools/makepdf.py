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
    body = re.sub(r'href="([^"]*)"', link, body)
    # a link to a page that is not in the PDF: only its text stays
    body = re.sub(r'<a data-nolink="1"[^>]*>(.*?)</a>', r"\1", body, flags=re.S)
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
.cover { height: 236mm; display: flex; flex-direction: column; justify-content: center; }
.cover h1 { font-size: 46px; margin: 0 0 10px; }
.cover p { font-size: 20px; color: #5f6480; margin: 0; }
.doc-contents { break-before: page; }
.doc-contents h2 { margin-top: 18px; font-size: 18px; border: 0; }
.doc-contents ol { margin: 4px 0 0 0; padding: 0; list-style: none; columns: 2; column-gap: 24px; }
.doc-contents li { break-inside: avoid; }
.anchor, .copy, .copy-btn, button { display: none !important; }
pre { white-space: pre-wrap !important; word-break: break-word; font-size: 11.5px !important; max-height: none !important; overflow: visible !important; }
pre code { white-space: pre-wrap !important; }
table { break-inside: avoid-page; font-size: 13px; }
img { max-width: 100%; break-inside: avoid; }
figure, .shot { break-inside: avoid; }
h1, h2, h3 { break-after: avoid; }
.callout { break-inside: avoid; }
.cards { display: block !important; }
.cards .card { display: block !important; margin: 2px 0; padding: 2px 0; box-shadow: none !important; border: 0 !important; background: none !important; }
.hero .btns { display: none; }
.pager, footer.site { display: none !important; }
"""


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
<section class="cover"><h1>RingDotNet</h1><p>Use .NET classes and methods from Ring programs</p><p style="margin-top:22px;font-size:15px">Documentation, %d pages: overview, tutorials, guides and reference. The class reference (one page for each namespace) is only in the HTML documentation.</p></section>
<section class="doc-contents"><h1>Contents</h1>%s</section>
<main>%s</main></body></html>""" % (CSS, len(allp), "".join(toc), "".join(parts))
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
        print("%d pages of the documentation -> %s (%.1f MB)" % (len(allp), pdf, os.path.getsize(pdf) / 1048576))
        return 0
    print("The browser did not write the PDF")
    return 1


if __name__ == "__main__":
    sys.exit(main())
