"""Audit of the public API of NuGet packages: what can Ring use, and what gets in the way?

    python auditpackages.py                   the packages of packages.txt, restored into a work folder, then one total table
    python auditpackages.py Serilog Dapper    only these packages
    python auditpackages.py --each            also one table for each package

Each package is restored with `dotnet publish` (like the tutorials do), so its DLL and the DLLs it needs are copied into one folder. The
DLLs that an empty project does not have are audited with auditassembly.ring. A package that cannot be restored is listed and left out.
"""
import os, subprocess, sys, shutil, glob

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


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    each = "--each" in sys.argv
    if args:
        names = args
    else:
        with open(os.path.join(HERE, "packages.txt")) as f:
            names = [l.split("#")[0].strip() for l in f if l.split("#")[0].strip()]
    ok, text = publish("baseline", [], os.path.join(WORK, "baseline"))
    baseline = set(dlls(os.path.join(WORK, "baseline")))
    audited, failed = {}, []
    for name in names:
        folder = os.path.join(WORK, name.split()[0])
        good, text = publish(name, [name], folder)
        if not good:
            reason = [line for line in text.replace(chr(13), "").split(chr(10)) if "error" in line]
            failed.append(name + ": " + (reason[-1][-160:] if reason else "restore failed"))
            continue
        for fname, path in dlls(folder).items():
            if fname in baseline or fname == "Probe.dll":
                continue
            audited.setdefault(fname, path)
        print("restored", name, flush=True)
    print("\nnot restored:", failed or "none")
    files = list(audited.values())
    print("assemblies to audit:", len(files))
    cmd = [RING, "auditassembly.ring"] + ([] if each else ["--quiet"]) + files
    env = dict(os.environ)
    env.pop("RING_HOME", None)
    env["PATH"] = os.path.join(ROOT, "extensions", "ringdotnet", "bin") + os.pathsep + os.path.join(ROOT, "bin") + os.pathsep + env["PATH"]
    subprocess.run(cmd, cwd=HERE, env=env)


main()
