"""Audit of the public API of NuGet packages: what can Ring use, and what gets in the way?

    python auditpackages.py                   the packages of packages.txt, restored into a work folder, then one total table
    python auditpackages.py Serilog Dapper    only these packages
    python auditpackages.py --each            one table for each package (instead of the total)
    python auditpackages.py --reuse           the folders of the earlier run, no restore

Each package is restored with `dotnet publish` (like the tutorials do), so its DLL and the DLLs it needs are copied into one folder. The
DLLs that an empty project does not have are audited with auditassembly.ring. A package that cannot be restored is listed and left out.
"""
import os, re, subprocess, sys, shutil, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
WORK = os.path.join(os.environ.get("TEMP", HERE), "ringdotnet-package-audit")
RING = os.environ.get("RING_EXE", r"B:\ring\bin\ring.exe")

PROJECT = """<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><TargetFramework>net9.0</TargetFramework><AssemblyName>Probe</AssemblyName><DebugType>none</DebugType>
    <SatelliteResourceLanguages>en</SatelliteResourceLanguages></PropertyGroup>
  <ItemGroup>%s</ItemGroup>
</Project>
"""


def publish(name, packages, folder):
    os.makedirs(folder, exist_ok=True)
    refs = "".join('<PackageReference Include="%s" Version="%s" />' % (p.split()[0], p.split()[1] if len(p.split()) > 1 else "*") for p in packages)
    with open(os.path.join(folder, "Probe.csproj"), "w") as f:
        f.write(PROJECT % refs)
    with open(os.path.join(folder, "Empty.cs"), "w") as f:
        f.write("class Empty { }\n")
    r = subprocess.run(["dotnet", "publish", folder, "-c", "Release", "-o", os.path.join(folder, "out"), "-nologo", "-v", "q"],
                       capture_output=True, text=True)
    return r.returncode == 0, (r.stdout + r.stderr)[-400:]


def dlls(folder):
    return {os.path.basename(p): p for p in glob.glob(os.path.join(folder, "out", "*.dll"))}


def run_audit(files, quiet):
    cmd = [RING, "auditassembly.ring"] + (["--quiet"] if quiet else []) + files
    env = dict(os.environ)
    env.pop("RING_HOME", None)
    env["PATH"] = os.path.join(ROOT, "extensions", "ringdotnet", "bin") + os.pathsep + os.path.join(ROOT, "bin") + os.pathsep + env["PATH"]
    return subprocess.run(cmd, cwd=HERE, env=env, capture_output=True, text=True).stdout


def parse_total(text):
    """The lines of the total of one run: [(count, tag, example)]"""
    rows = []
    inside = False
    for line in text.replace(chr(13), "").split(chr(10)):
        if line.startswith("== total"):
            inside = True
            continue
        if line.startswith("summary"):
            break
        m = re.match(r"\s*(\d+)  (.*?)(?:   e\.g\. (.*))?$", line)
        if inside and m:
            rows.append((int(m.group(1)), m.group(2), m.group(3) or ""))
    return rows


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    each = "--each" in sys.argv
    reuse = "--reuse" in sys.argv          # the folders of an earlier run are used as they are (no restore)
    if args:
        names = args
    else:
        with open(os.path.join(HERE, "packages.txt")) as f:
            names = [l.split("#")[0].strip() for l in f if l.split("#")[0].strip()]
    if not reuse:
        publish("baseline", [], os.path.join(WORK, "baseline"))
    baseline = set(dlls(os.path.join(WORK, "baseline")))
    audited, failed = {}, []
    per_package = []          # [(package, [dll paths])]: each package is audited in a process of its own, so that two versions of a dependency do not meet
    for name in names:
        folder = os.path.join(WORK, name.split()[0])
        if reuse and os.path.isdir(os.path.join(folder, "out")):
            good = True
        else:
            good, text = publish(name, [name], folder)
        if not good:
            reason = [line for line in text.replace(chr(13), "").split(chr(10)) if "error" in line]
            failed.append(name + ": " + (reason[-1][-160:] if reason else "restore failed"))
            continue
        mine = []
        for fname, path in dlls(folder).items():
            if fname in baseline or fname == "Probe.dll" or fname in audited:
                continue
            audited[fname] = path
            mine.append(path)
        per_package.append((name, mine))
        print("restored", name, flush=True)
    print("\nnot restored:", failed or "none")
    print("assemblies to audit:", len(audited))
    if each:
        for name, files in per_package:
            if files:
                print("\n#####", name)
                print(run_audit(files, False))
        return
    totals, examples, order = {}, {}, []
    for name, files in per_package:
        if not files:
            continue
        for count, tag, example in parse_total(run_audit(files, True)):
            if tag not in totals:
                totals[tag], examples[tag] = 0, ""
                order.append(tag)
            totals[tag] += count
            if not examples[tag]:
                examples[tag] = example
    print("\n== total of %d assemblies" % len(audited))
    for kind in ("OK", "INFO", "GAP"):
        rows = sorted([(totals[t], t) for t in order if t.strip().startswith(kind)], key=lambda r: -r[0])
        for count, tag in rows:
            print("%7d  %s%s" % (count, tag, ("   e.g. " + examples[tag]) if examples[tag] else ""))
    def get(tag):
        return totals.get(tag, 0)
    types = get("INFO type: public types")
    usable = get("OK   type: wrapped (class, struct, interface)") + get("OK   type: enum (a text in Ring)") + get("OK   type: delegate (a callback in Ring)")
    methods = get("INFO method: public methods")
    callable_ = sum(v for t, v in totals.items() if t.startswith("OK   method: callable"))
    print("\nsummary")
    if types:
        print("  types that Ring can use (wrapped, enums, delegates): %d %% (%d of %d)   (generic definitions %d, nested %d)" % (usable * 100 // types, usable, types, get("INFO type: generic type definition (wrapped, made with :typeArguments)"), get("INFO type: nested type (wrapped, named after the types around it)")))
    if methods:
        print("  methods that can be called, in the types that are wrapped: %d %% (%d of %d)" % (callable_ * 100 // methods, callable_, methods))
    print("  members (methods, constructors, properties) in types that are not wrapped: %d" % get("GAP  members of types that are not wrapped"))


main()
