/*
	Generate the Ring wrapper classes of .NET types (like RingQt's generated classes).

	Usage (from this folder, ring_dotnet.dll and the bridge on the PATH):
		ring gendotnet.ring                    generate every namespace of dotnetmanifest.ring
		ring gendotnet.ring System.IO ...      generate only these namespaces

	Output (per namespace): ../../libraries/dotnetlib/generated/<Namespace>.ring (the loader used by dnImport)
	                        ../../libraries/dotnetlib/generated/<Namespace>/<ClassName>.ring
*/

load "gendotnetcore.ring"
load "dotnetmanifest.ring"

C_OUTDIR = "../../libraries/dotnetlib/generated/"

func main
	aWanted = []
	for x = 3 to len(sysargv)
		aWanted + sysargv[x]
	next
	genAll(aWanted)
