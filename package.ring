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
		"libraries/dotnetlib/generated\Console.ring",
		"libraries/dotnetlib/generated\DateTime.ring",
		"libraries/dotnetlib/generated\Directory.ring",
		"libraries/dotnetlib/generated\Environment.ring",
		"libraries/dotnetlib/generated\File.ring",
		"libraries/dotnetlib/generated\Guid.ring",
		"libraries/dotnetlib/generated\HttpClient.ring",
		"libraries/dotnetlib/generated\Math.ring",
		"libraries/dotnetlib/generated\Path.ring",
		"libraries/dotnetlib/generated\Random.ring",
		"libraries/dotnetlib/generated\Stopwatch.ring",
		"libraries/dotnetlib/generated\StringBuilder.ring",
		"libraries/dotnetlib/generated\TimeSpan.ring",
		"libraries/dotnetlib/generated\dotnetclasses.ring",
		"samples/UsingDotNet/test02_natural.ring",
		"tools/gendotnet.ring",
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
