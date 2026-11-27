#!/usr/bin/env python3
"""Checks a change of the generator, the bridge or the manifest before it is committed.

    python tools/dotnettools/checkgenerator.py                 regenerate the library, then run every check
    python tools/dotnettools/checkgenerator.py --no-generate   the checks only (the library is as it is)
    python tools/dotnettools/checkgenerator.py --ring PATH     the ring executable (default: the environment variable RING, or ring)
    python tools/dotnettools/checkgenerator.py --allow-large   a big change of the generated files is expected (a new rule of the generator)
    python tools/dotnettools/checkgenerator.py --all-packages  also the package tests (all of them: about ten minutes)
    python tools/dotnettools/checkgenerator.py --update-baseline   write the number of types without a class as the new baseline

The checks, in order:
  1. gendotnet.ring makes the whole library (without errors).
  2. The size of the change of the generated files (files and lines against the last commit, and the kinds of line that changed: read them, a rule that
     copies methods into derived classes shows here as thousands of added lines).
  3. importall.ring imports every namespace of the manifest: every generated file loads.
  4. The tests that use the generated classes most (the classes of the library, extension methods, generic types, keywords, your own assembly).
  5. A few package tests whose classes are made again by the generator now (fluent calls in callbacks, generic pipelines, properties named like Ring
     words, generic extension methods). The cache of a package is made again when the generator, the bridge or the library changed.
  6. The number of public types that have no class (auditcoverage.ring) against tools/dotnettools/coverage-baseline.txt: it must not grow.
The exit code is 0 only when every check passed.
"""
import argparse, os, re, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GENERATED = "libraries/dotnetlib/generated"
TESTS = os.path.join(ROOT, "samples", "UsingDotNet", "tests")
BASELINE = os.path.join(HERE, "coverage-baseline.txt")

LIBRARY_TESTS = ["test_foundation.ring", "test_collections.ring", "test_extension_methods.ring", "test_classindex.ring", "test_more_classes.ring",
                 "test_web_runtime.ring", "test_odbc_sqlitepcl.ring", "test_userassembly.ring"]
PACKAGE_TESTS = ["pkgtest_questpdf.ring", "pkgtest_mlnet_chess.ring", "pkgtest_esprima.ring", "pkgtest_fluentvalidation.ring"]

results = []


def environment():
    env = dict(os.environ)
    env.pop("RING_HOME", None)
    env["PATH"] = os.path.join(ROOT, "bin") + os.pathsep + env.get("PATH", "")
    return env


def run(command, cwd, timeout=3600):
    started = time.time()
    done = subprocess.run(command, cwd=cwd, env=environment(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=timeout)
    return done.returncode, done.stdout, time.time() - started


def report(name, ok, detail=""):
    results.append((name, ok))
    print("%-5s %s%s" % ("PASS" if ok else "FAIL", name, ("  -  " + detail) if detail else ""))
    sys.stdout.flush()


def git(*arguments):
    return subprocess.run(["git"] + list(arguments), cwd=ROOT, stdout=subprocess.PIPE, text=True, encoding="utf-8", errors="replace").stdout


def check_generate(ring):
    code, output, seconds = run([ring, "gendotnet.ring"], HERE)
    failed = code != 0 or re.search(r"Error \(R\d+\)|Line \d+ Error|DotNet Error", output) is not None
    report("generate the library", not failed, "%d seconds" % seconds if not failed else output.strip().splitlines()[0][:150] if output.strip() else "no output")
    return not failed


def check_size(max_files, max_lines):
    numstat = git("diff", "--numstat", "--", GENERATED).strip().splitlines()
    untracked = [l for l in git("status", "--short", "--", GENERATED).splitlines() if l.startswith("??")]
    files = len(numstat) + len(untracked)
    added = sum(int(l.split("\t")[0]) for l in numstat if l.split("\t")[0].isdigit())
    removed = sum(int(l.split("\t")[1]) for l in numstat if l.split("\t")[1].isdigit())
    ok = files <= max_files and added + removed <= max_lines
    report("the change of the generated files", ok, "%d files changed or new, %d lines added, %d removed (limits: %d files, %d lines; --allow-large for a new rule)" % (files, added, removed, max_files, max_lines))
    if files > 0:
        diff = git("diff", "-U0", "--", GENERATED)
        kinds = {}
        for line in diff.splitlines():
            if (line.startswith("+") or line.startswith("-")) and not line.startswith("+++") and not line.startswith("---"):
                key = line[0] + re.sub(r'"[A-Za-z_@]+"', '"X"', re.sub(r"\b(Func|Class) [A-Za-z_@]+", r"\1 X", line[1:])).strip()
                kinds[key] = kinds.get(key, 0) + 1
        print("      the kinds of line that changed (count, line):")
        for key, count in sorted(kinds.items(), key=lambda kv: -kv[1])[:8]:
            print("        %6d  %s" % (count, key[:110]))
    return ok


def check_import(ring):
    code, output, seconds = run([ring, "importall.ring"], HERE)
    match = re.search(r"IMPORTED (\d+) namespaces, (\d+) failed", output)
    ok = code == 0 and match is not None and match.group(2) == "0"
    detail = match.group(0) if match else (output.strip().splitlines()[0][:150] if output.strip() else "no output")
    if match and match.group(2) != "0":
        detail += "  " + " | ".join(l.strip() for l in output.splitlines() if "FAILED" in l)[:300]
    report("every namespace of the manifest imports", ok, detail)
    return ok


def check_test(ring, directory, name):
    if name == "test_userassembly.ring":
        shutil.rmtree(os.path.join(TESTS, "UserLib", "generated"), ignore_errors=True)          # made again by the generator of now
    code, output, seconds = run([ring, name], directory, timeout=1800)
    match = re.search(r"TESTS: (\d+) passed, (\d+) failed", output)
    ok = match is not None and match.group(2) == "0"
    detail = ("%s, %d seconds" % (match.group(0), seconds)) if match else ("SKIPPED" if "SKIPPED" in output else (output.strip().splitlines() or ["no summary"])[0][:200])
    if "SKIPPED" in output and not match:
        ok = True
    report(name, ok, detail)
    return ok


def check_coverage(ring, update):
    code, output, seconds = run([ring, "auditcoverage.ring"], HERE)
    match = re.search(r"without a Ring class: (\d+)", output)
    if not match:
        report("types without a class", False, "the audit gave no total")
        return False
    count = int(match.group(1))
    baseline = None
    if os.path.exists(BASELINE):
        text = open(BASELINE, encoding="utf-8").read().strip()
        baseline = int(text) if text.isdigit() else None
    if update or baseline is None:
        open(BASELINE, "w", encoding="utf-8", newline="\n").write("%d\n" % count)
        report("types without a class", True, "%d (the baseline was written)" % count)
        return True
    ok = count <= baseline
    report("types without a class", ok, "%d now, %d in the baseline%s" % (count, baseline, "" if ok else ": types lost their class"))
    return ok


def main():
    parser = argparse.ArgumentParser(description="Checks a change of the generator, the bridge or the manifest")
    parser.add_argument("--ring", default=os.environ.get("RING", "ring"))
    parser.add_argument("--no-generate", action="store_true")
    parser.add_argument("--allow-large", action="store_true")
    parser.add_argument("--max-files", type=int, default=15)
    parser.add_argument("--max-lines", type=int, default=600)
    parser.add_argument("--all-packages", action="store_true")
    parser.add_argument("--update-baseline", action="store_true")
    options = parser.parse_args()
    ring = options.ring
    max_files, max_lines = (10 ** 6, 10 ** 9) if options.allow_large else (options.max_files, options.max_lines)
    started = time.time()
    if not options.no_generate:
        if not check_generate(ring):
            print("the library could not be made: the other checks are skipped")
            return 1
    check_size(max_files, max_lines)
    check_import(ring)
    for name in LIBRARY_TESTS:
        check_test(ring, TESTS, name)
    packages = os.path.join(TESTS, "packages")
    for name in PACKAGE_TESTS:
        check_test(ring, packages, name)
    if options.all_packages:
        code, output, seconds = run(["sh", os.path.join(TESTS, "run.sh"), ring, "--packages-only"], ROOT, timeout=7200)
        summary = [l for l in output.splitlines() if " failed (" in l]
        report("all the package tests", code == 0, summary[-1] if summary else "no summary")
    check_coverage(ring, options.update_baseline)
    failed = [name for name, ok in results if not ok]
    print("\n%d checks, %d failed (%d seconds)" % (len(results), len(failed), time.time() - started))
    for name in failed:
        print("  FAILED: " + name)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
