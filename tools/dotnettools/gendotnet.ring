/*
	Generate the Ring wrapper classes of .NET types (like RingQt's generated classes).

	Usage (from this folder, ring_dotnet.dll and the bridge on the PATH):
		ring gendotnet.ring                    generate every namespace of dotnetmanifest.ring
		ring gendotnet.ring System.IO ...      generate only these namespaces (for a try: base classes of other namespaces are left out;
		                                       the files of the library are made by a run without names)

	Output (per namespace): ../../libraries/dotnetlib/generated/<Namespace>.ring (the loader used by dnImport)
	                        ../../libraries/dotnetlib/generated/<Namespace>.classes.ring (all the classes of the namespace)
*/

load "gendotnetcore.ring"
load "dotnetmanifest.ring"

C_OUTDIR = "../../libraries/dotnetlib/generated/"
lMergeIndex = false

func main
	aWanted = []
	for x = 3 to len(sysargv)
		aWanted + sysargv[x]
	next
	genAll(aWanted)
