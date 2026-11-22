/*
	DotNetLib - Use .NET classes and methods from Ring programs (through the RingDotNet extension)

	load "dotnet.ring"
	using {
		"System"
		"System.IO"				# the generated classes of a namespace are loaded when the namespace is named
	}

	oFile = new File()
	? oFile.Exists("data.txt")

	The files of this library:
		globals.ring      the global variables (the wire format tags, the registers of the classes)
		functions.ring    the dn... functions: packing of requests, dnNew, dnStatic, dnCallback, dnImport, dnBuffer ...
		classes.ring      DotNetObject (the reference to a .NET object) and DotNetCallback
		using.ring        using { } (imports namespaces and starts the runtime mode that the names need)
		linq.ring         dnQuery, the LINQ helpers (loaded with the namespace System.Linq)
		gui.ring, wpf.ring   the helpers of Windows Forms and WPF programs (loaded with their namespaces)
		web.ring, data.ring  the web server and the Entity Framework layer (loaded when the program asks for them)
		generated/        the Ring classes of the .NET namespaces (made by tools/dotnettools/gendotnet.ring: do not edit them)
*/

# Folder of this library (dnImport loads the generated classes from its "generated" folder)
cDotNetLibFolder = filename()

load "../../extensions/ringdotnet/dotnet.ring"
load "globals.ring"
load "functions.ring"
load "classes.ring"
load "web.ring"
load "data.ring"
load "using.ring"

# Keep only the folder (with a trailing "/") of the path above
cDotNetLibFolder = dnFolderOf(cDotNetLibFolder)

# using { "System" "System.Text" } imports namespaces (see using.ring)
using = new UsingClass
