aPackageInfo = [
	:name = "The RingDotNet Package",
	:description = "Our RingDotNet package (use .NET classes and methods from Ring programs) using the Ring programming language",
	:folder = "ringdotnet",
	:developer = "Mahmoud Fayed",
	:email = "msfclipper@yahoo.com",
	:license = "MIT License",
	:version = "1.0.0",
	:ringversion = "1.27",
	:versions = 	[
		[
			:version = "1.0.0",
			:branch = "master"
		]
	],
	:libs = 	[

	],
	:files = 	[
		"main.ring",
		"README.md"
	],
		:ringfolderfiles = 	[
		"bin/load/dotnetlib.ring",
		"extensions/ringdotnet/README.md",
		"extensions/ringdotnet/buildclang.sh",
		"extensions/ringdotnet/buildclang_win.bat",
		"extensions/ringdotnet/buildgcc.sh",
		"extensions/ringdotnet/buildvc_x64.bat",
		"extensions/ringdotnet/ring_dotnet.c",
		"extensions/ringdotnet/dotnet.ring",
		"extensions/ringdotnet/bridge/Bridge.cs",
		"extensions/ringdotnet/bridge/RingDotNet.Bridge.csproj",
		"libraries/dotnetlib/dotnetlib.ring",
		"libraries/dotnetlib/globals.ring",
		"libraries/dotnetlib/functions.ring",
		"libraries/dotnetlib/classes.ring",
		"samples/UsingDotNet/test01_hello.ring",
		"tools/ring2exe/libs/dotnet.ring"
	],
	:windowsfiles = 	[

	],
	:linuxfiles = 	[

	],
	:ubuntufiles = 	[

	],
	:fedorafiles = 	[

	],
	:freebsdfiles = 	[

	],
	:macosfiles = 	[

	],
	:windowsringfolderfiles = 	[
		"bin/ring_dotnet.dll",
		"bin/RingDotNet.Bridge.dll",
		"bin/RingDotNet.Bridge.runtimeconfig.json",
		"bin/RingDotNet.Bridge.deps.json"
	],
	:linuxringfolderfiles = 	[

	],
	:ubunturingfolderfiles = 	[

	],
	:fedoraringfolderfiles = 	[

	],
	:freebsdringfolderfiles = 	[

	],
	:macosringfolderfiles = 	[

	],
	:run = "ring main.ring",
	:windowsrun = "",
	:linuxrun = "",
	:macosrun = "",
	:ubunturun = "",
	:fedorarun = "",
	:setup = "",
	:windowssetup = "",
	:linuxsetup = "",
	:macossetup = "",
	:ubuntusetup = "",
	:fedorasetup = "",
	:remove = "",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = ""
]
