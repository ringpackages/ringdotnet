"""The class reference: one page per wrapped namespace (docs/api/<namespace>.html) and the index page (docs/api.html).

Data: docs/tools/api-data/api.jsonl (made by dumpapi.py: the .NET API of every class) and the generated Ring classes
(libraries/dotnetlib/generated), which say how each member is called from Ring."""
import html
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
ROOT = os.path.dirname(DOCS)
GEN = os.path.join(ROOT, "libraries", "dotnetlib", "generated")
DATA = os.path.join(HERE, "api-data", "api.jsonl")

KEYWORDS = set("""next step call put get set load from to on off exit loop end return done try catch ok class func new import package private see give bye
again break continue and or not if but else elseif for in while switch other""".split())


def esc(t):
    return html.escape(str(t), quote=False)


def load_api():
    """{ (namespace, ring class): json dict or None }"""
    api = {}
    with open(DATA, encoding="utf-8") as f:
        for ln in f:
            ln = ln.rstrip("\n")
            if not ln:
                continue
            ns, cls, rest = ln.split("\t", 2)
            api[(ns, cls)] = None if rest.startswith("ERROR") else json.loads(rest)
    return api


def parse_class_file(ns, cls):
    """What the generated Ring class offers: base class, attributes, and for each Func: (ring name, parameter count, .NET name, kind)"""
    path = os.path.join(GEN, ns, cls + ".ring")
    info = {"base": "", "attrs": set(), "funcs": [], "ctor_arities": []}
    if not os.path.exists(path):
        return info
    text = open(path, encoding="utf-8").read()
    m = re.search(r"^Class\s+(\w+)\s+from\s+(\w+)", text, re.M | re.I)
    if m:
        info["base"] = m.group(2)
    blocks = re.split(r"(?m)^\tFunc\s+", text)
    head = blocks[0]
    for ln in head.split("\n"):
        ma = re.match(r"^\t(\w+)\s*$", ln)
        if ma:
            info["attrs"].add(ma.group(1).lower())
    for b in blocks[1:]:
        first, _, body = b.partition("\n")
        mf = re.match(r"(\w+)(?:\s+([\w,]+))?\s*$", first)
        if not mf:
            continue
        ring, params = mf.group(1), mf.group(2)
        n = len(params.split(",")) if params else 0
        net = None
        kind = "method"
        mm = re.search(r'"(call|callnamed|get|set|setevent|clearevent)",\[[^\]]*?,"(\w+)"', body)
        if mm:
            net = mm.group(2)
            if mm.group(1) in ("get", "set"):
                kind = mm.group(1)
            elif mm.group(1) in ("setevent", "clearevent"):
                kind = "event"
        if "dnIsNamed(P1)" in body:
            kind = "dispatch"
        info["funcs"].append({"ring": ring, "n": n, "net": net, "kind": kind, "null": 'isstring(P1) and P1 = ""' in body,
                              "one": bool(re.search(r'"call",\[[^\]]*\]\)', body))})
    return info


def sig_params(params):
    out = []
    for p in params:
        mod = (p.get("m") + " ") if p.get("m") else ""
        opt = " = …" if p.get("o") else ""
        out.append("%s%s %s%s" % (mod, p["t"], p["n"], opt))
    return ", ".join(out)


def ring_forms(name, funcs, static_only=False):
    """The ways to call a .NET method from Ring"""
    forms = []
    for f in funcs:
        if f["net"] != name or f["kind"] not in ("method", "dispatch"):
            continue
        r = f["ring"]
        if f["kind"] == "dispatch":
            if f["null"]:
                forms.append("%s(NULL)" % r)
            forms.append("%s(value)" % r)
            forms.append("%s([ :name = value ])" % r)
        else:
            args = ",".join("p%d" % (i + 1) for i in range(f["n"]))
            forms.append("%s(%s)" % (r, args))
    forms.sort(key=lambda x: (re.match(r"\w+_\d+\(", x) is not None, 0))
    seen, out = set(), []
    for x in forms:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def anchor(cls):
    return "c-" + cls


def render_class(ns, cls, data, cinfo, wrapped, by_full):
    out = []
    if data is None:
        out.append('<details class="cls" id="%s"><summary><b>%s</b> <span class="pill">no reflection data</span></summary></details>' % (anchor(cls), esc(cls)))
        return "\n".join(out)
    kind = data["kind"]
    tags = [kind]
    for k in ("static", "abstract", "sealed"):
        if data.get(k):
            tags.append(k)
    base = ""
    if data.get("base"):
        b = by_full.get(data.get("basefull", ""))
        if b:
            base = ' · extends <a href="%s.html#%s">%s</a>' % (b[0] if b[0] != ns else ns, anchor(b[1]), esc(b[1])) if b[0] != ns else ' · extends <a href="#%s">%s</a>' % (anchor(b[1]), esc(b[1]))
        else:
            base = " · extends %s" % esc(data["base"])
    summary = '<b>%s</b> <span class="muted">%s%s</span>' % (esc(cls), " ".join(tags), base)
    out.append('<details class="cls" id="%s"><summary>%s</summary>' % (anchor(cls), summary))
    out.append('<div class="clsbody">')
    out.append('<p class="net"><code>%s</code> · assembly <code>%s</code></p>' % (esc(data["full"]), esc(data["asm"])))
    if data.get("interfaces"):
        out.append('<p class="muted">Implements: %s</p>' % esc(", ".join(data["interfaces"])))

    # enums
    if data.get("values"):
        out.append("<h4>Values</h4><p>Enum values are strings in Ring: <code>%s</code></p>" % esc(", ".join('"%s"' % v for v in data["values"][:60]) + (" …" if len(data["values"]) > 60 else "")))

    wrapped_names = wrapped  # pretty names of documented ancestors

    def own(item):
        f = item.get("from")
        return (not f) or (f not in wrapped_names)

    # constructors
    ctors = data.get("ctors", [])
    if ctors and kind != "enum":
        rows = []
        for c in ctors:
            rows.append("<tr><td><code>new %s(%s)</code></td></tr>" % (esc(cls), esc(sig_params(c))))
        out.append('<h4>Constructors</h4><div class="tablewrap"><table class="api"><tbody>%s</tbody></table></div>' % "".join(rows))
        out.append('<p class="muted">Ring: <code>new %s(args)</code> uses one constructor, the others are <code>New_N(args)</code>; or <code>dnNew("%s",[ :param = value ])</code> by parameter names.</p>' % (esc(cls), esc(cls)))

    # properties and fields
    props = [p for p in data.get("props", []) if own(p)]
    fields = [p for p in data.get("fields", []) if own(p)]
    if props or fields:
        rows = []
        for p in props + fields:
            acc = []
            if p.get("r", 1):
                acc.append("read")
            if p.get("w"):
                acc.append("write")
            if p.get("c"):
                acc = ["constant"]
            nm = p["n"]
            low = nm.lower()
            is_attr = low in cinfo["attrs"]
            if is_attr:
                use = "<code>o.%s</code>%s" % (esc(nm), " <code>o.%s = v</code>" % esc(nm) if p.get("w") else "")
            else:
                use = "<code>o.get%s()</code>%s" % (esc(nm), " <code>o.set%s(v)</code>" % esc(nm) if p.get("w") else "")
            rows.append("<tr><td><code>%s</code></td><td><code>%s</code></td><td>%s%s</td><td>%s</td></tr>" % (
                esc(nm), esc(p["t"]), esc(", ".join(acc)), " · static" if p.get("s") else "", use))
        out.append('<h4>Properties and fields</h4><div class="tablewrap"><table class="api"><thead><tr><th>Name</th><th>Type</th><th>Access</th><th>In Ring</th></tr></thead><tbody>%s</tbody></table></div>' % "".join(rows))

    # indexers
    for ix in data.get("indexers", []):
        out.append('<h4>Indexer</h4><p><code>o.Item(%s %s)</code> → <code>%s</code>%s</p>' % (esc(ix["i"]), esc(ix["n"]), esc(ix["t"]),
                   (" · <code>o.SetItem(%s,value)</code>" % esc(ix["n"])) if ix.get("w") else ""))

    # methods
    groups = {}
    for m in data.get("methods", []):
        if own(m):
            groups.setdefault(m["n"], []).append(m)
    if groups:
        rows = []
        for name in sorted(groups, key=lambda x: x.lower()):
            ms = groups[name]
            forms = ring_forms(name, cinfo["funcs"])
            sigs = []
            for m in ms:
                gen = "<%s>" % m["g"] if m.get("g") else ""
                sigs.append("%s%s %s%s(%s)" % ("static " if m.get("s") else "", m["r"], name, gen, sig_params(m["p"])))
            rows.append("<tr><td><code>%s</code></td><td>%s</td><td>%s</td></tr>" % (
                esc(name), "<br>".join("<code>%s</code>" % esc(x) for x in forms) if forms else '<span class="muted">—</span>',
                "<br>".join("<code>%s</code>" % esc(x) for x in sigs)))
        out.append('<h4>Methods</h4><div class="tablewrap"><table class="api"><thead><tr><th>Method</th><th>Ring call</th><th>.NET overloads</th></tr></thead><tbody>%s</tbody></table></div>' % "".join(rows))

    # events
    events = [e for e in data.get("events", []) if own(e)]
    if events:
        rows = []
        for e in events:
            rows.append("<tr><td><code>%s</code></td><td><code>%s</code></td><td><code>o.set%sEvent(code)</code> · <code>o.clear%sEvent()</code></td></tr>" % (
                esc(e["n"]), esc(e["t"]), esc(e["n"]), esc(e["n"])))
        out.append('<h4>Events</h4><div class="tablewrap"><table class="api"><thead><tr><th>Event</th><th>Handler type</th><th>In Ring</th></tr></thead><tbody>%s</tbody></table></div>' % "".join(rows))

    if data.get("base") and base:
        out.append('<p class="muted">Members of the base class are inherited.</p>')
    out.append("</div></details>")
    return "\n".join(out)


def build(page_html, DOCS_DIR):
    api = load_api()
    by_full = {}
    for (ns, cls), d in api.items():
        if d:
            by_full[d["full"]] = (ns, cls)
    namespaces = {}
    for (ns, cls) in api:
        namespaces.setdefault(ns, []).append(cls)
    os.makedirs(os.path.join(DOCS_DIR, "api"), exist_ok=True)
    index_items = []
    ns_rows = []
    total = 0
    for ns in sorted(namespaces):
        classes = sorted(namespaces[ns], key=lambda x: x.lower())
        parts = []
        chips = []
        for cls in classes:
            data = api[(ns, cls)]
            cinfo = parse_class_file(ns, cls)
            # the documented ancestors: their members are inherited, not repeated
            wrapped = set()
            cur = data
            guard = 0
            while cur and cur.get("basefull") and guard < 30:
                b = by_full.get(cur["basefull"])
                if not b:
                    break
                bd = api[b]
                wrapped.add(bd["name"] if bd else b[1])
                cur = bd
                guard += 1
            parts.append(render_class(ns, cls, data, cinfo, wrapped, by_full))
            kind = data["kind"] if data else "class"
            chips.append('<a href="#%s">%s</a>' % (anchor(cls), esc(cls)))
            index_items.append([cls, ns, kind])
            total += 1
        asm = ""
        for cls in classes:
            if api[(ns, cls)]:
                asm = api[(ns, cls)]["asm"]
                break
        ns_rows.append((ns, len(classes), asm))
        body = ('<p class="lead">%d wrapped types. Load them with <code>using { "%s" }</code>. Click a class to open it.</p>' % (len(classes), esc(ns))
                + '<div class="chips">%s</div>' % " ".join(chips) + "\n".join(parts))
        page = page_html("api/" + ns, ns, "", body, "api", root="../", toc=False, heading=ns)
        with open(os.path.join(DOCS_DIR, "api", ns + ".html"), "w", encoding="utf-8") as f:
            f.write(page)
    # the index page
    rows = "".join('<tr><td><a href="api/%s.html">%s</a></td><td>%d</td><td><code>%s</code></td></tr>' % (n, esc(n), c, esc(a)) for n, c, a in ns_rows)
    body = ('<p class="lead">Every .NET class that RingDotNet wraps: %d classes, structs, interfaces and enums in %d namespaces. '
            'Each entry shows the .NET type, constructors, properties (as Ring attributes), methods (with the way to call them from Ring), and events.</p>'
            '<div class="callout tip"><span class="t">Tip</span><p>Use the search box (<kbd>/</kbd>) to find a class by name. '
            'Load a namespace with <code>using { "System.Text" }</code>. How members are named in Ring: <a href="concepts.html">Core concepts</a>.</p></div>'
            '<div class="tablewrap"><table><thead><tr><th>Namespace</th><th>Types</th><th>Assembly</th></tr></thead><tbody>%s</tbody></table></div>') % (total, len(ns_rows), rows)
    with open(os.path.join(DOCS_DIR, "api.html"), "w", encoding="utf-8") as f:
        f.write(page_html("api", "Class reference", "", body, "api", heading="Class reference"))
    with open(os.path.join(DOCS_DIR, "assets", "api-index.js"), "w", encoding="utf-8") as f:
        f.write("window.API_INDEX = " + json.dumps(index_items, separators=(",", ":")) + ";")
    return total, len(ns_rows)
