#!/usr/bin/env python3
"""Builds extensions/ringdotnet.zip: the package files, with the paths they have inside the Ring folder.

RingPM copies this one zip into ring/extensions (one file instead of thousands) and setup.ring extracts it
into the Ring folder. Run it again whenever the library, the samples, the DLLs or the tests change:
    python tools/dotnettools/makepackage.py
"""
import os, subprocess, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PREFIXES = ("libraries/", "extensions/ringdotnet/", "samples/", "tools/", "bin/")
MANIFEST = "extensions/ringdotnet/package-files.txt"      # the list of the files (used by uninstall.ring)

def package_files():
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True, encoding="utf-8")
    files = [f for f in out.split("\n") if f.startswith(PREFIXES)]
    return sorted(f for f in files if os.path.exists(os.path.join(ROOT, f)))

def main():
    files = package_files()
    manifest = "\n".join(files + [MANIFEST]) + "\n"
    target = os.path.join(ROOT, "extensions", "ringdotnet.zip")
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        # directory entries first: the extractor of ringzip needs them
        folders = sorted({"/".join(f.split("/")[:i]) + "/" for f in files for i in range(1, f.count("/") + 1)})
        for d in folders:
            z.writestr(zipfile.ZipInfo(d), "")
        for f in files:
            z.write(os.path.join(ROOT, f), f)
        z.writestr(MANIFEST, manifest)
    print("%d files, %.1f MB -> %s" % (len(files) + 1, os.path.getsize(target) / 1048576, target))

if __name__ == "__main__":
    sys.exit(main())
