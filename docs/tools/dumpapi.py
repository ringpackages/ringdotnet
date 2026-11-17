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


def main():
    os.makedirs(OUT, exist_ok=True)
    lines = []
    for loader in sorted(os.listdir(GEN)):
        if not loader.endswith(".ring") or loader == "classindex.ring":
            continue
        ns = loader[:-5]
        if not os.path.isdir(os.path.join(GEN, ns)):
            continue
        text = open(os.path.join(GEN, loader), encoding="utf-8").read()
        for m in re.finditer(r'dnRegisterClass\("([^"]+)","([^"]+)",\d+\)', text):
            net, cls = m.group(1), m.group(2)
            path = os.path.join(GEN, ns, cls + ".ring")
            qualified = net
            if os.path.exists(path):
                src = open(path, encoding="utf-8").read()
                q = re.search(r"dnTypeCached\('([^']+)'\)|dnCreate\('([^']+)'", src)
                if q:
                    qualified = q.group(1) or q.group(2)
            lines.append("\t".join([ns, cls, qualified]))
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
