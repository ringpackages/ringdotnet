/*
	DotNetLib - Use .NET classes and methods from Ring programs (using the RingDotNet extension)

	load "dotnetlib.ring"
	dnImport("System.IO")		# load the generated classes of a namespace
*/

# Folder of this library (dnImport loads the generated classes from its "generated" folder)
cDotNetLibFolder = filename()

load "../../extensions/ringdotnet/dotnet.ring"
load "globals.ring"
load "generated/classindex.ring"
load "functions.ring"
load "classes.ring"

# Keep only the folder (with a trailing "/") of the path above
cDotNetLibFolder = dnFolderOf(cDotNetLibFolder)
