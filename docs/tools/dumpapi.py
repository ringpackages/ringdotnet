#!/usr/bin/env python3
"""Makes docs/tools/api-data/api.jsonl: the API (from .NET reflection) of every wrapped class. Run it before build.py when the classes change."""
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GEN = os.path.join(ROOT, "libraries", "dotnetlib", "generated")
OUT = os.path.join(HERE, "api-data")
RING = os.environ.get("RING_EXE", "B:/ring/bin/ring.exe")


def qualified_names(ns, nets):
    """{Ring class: assembly qualified .NET name}: the generated code of a class has its type as 'Namespace.Type, Assembly'"""
    result = {}
    path = os.path.join(GEN, ns + ".classes.ring")
    if not os.path.exists(path):
        return result
    text = open(path, encoding="utf-8").read()
    for block in text.split("\nClass ")[1:]:
        name = re.match(r"(\w+)", block).group(1)
        net = nets.get(name)
        if not net:
            continue
        q = re.search(r"'(" + re.escape(net) + r", [^']+)'", block)
        if q:
            result[name] = q.group(1)
    return result


def main():
    os.makedirs(OUT, exist_ok=True)
    lines = []
    for loader in sorted(os.listdir(GEN)):
        if not loader.endswith(".ring") or loader.endswith(".classes.ring") or loader == "classindex.ring":
            continue
        ns = loader[:-5]
        text = open(os.path.join(GEN, loader), encoding="utf-8").read()
        registered = re.findall(r'dnRegisterClass\("([^"]+)","([^"]+)",\d+\)', text)
        names = qualified_names(ns, {cls: net for net, cls in registered})
        for net, cls in registered:
            lines.append("	".join([ns, cls, names.get(cls, net)]))
    types = os.path.join(OUT, "types.txt")
    with open(types, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    env = dict(os.environ)
    env.pop("RING_HOME", None)
    env["PATH"] = os.path.join(ROOT, "bin") + os.pathsep + env.get("PATH", "")
    out = os.path.join(OUT, "api.jsonl")
    r = subprocess.run([RING, "dumpapi.ring", types, out], cwd=HERE, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=3000)
    print((r.stdout + r.stderr).strip()[-600:])


if __name__ == "__main__":
    main()
