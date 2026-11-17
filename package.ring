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
		"extensions/ringdotnet/bridge/Bridge.cs",
		"extensions/ringdotnet/bridge/RingDotNet.Bridge.csproj",
		"extensions/ringdotnet/bridge/RingDotNet.Desktop.runtimeconfig.json",
		"extensions/ringdotnet/buildclang.sh",
		"extensions/ringdotnet/buildclang_win.bat",
		"extensions/ringdotnet/buildgcc.sh",
		"extensions/ringdotnet/buildvc_x64.bat",
		"extensions/ringdotnet/dotnet.ring",
		"extensions/ringdotnet/ring_dotnet.c",
		"libraries/dotnetlib/classes.ring",
		"libraries/dotnetlib/dotnetlib.ring",
		"libraries/dotnetlib/functions.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/NumberDictionary.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/NumberList.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/ObjectDictionary.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/ObjectList.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/StringDictionary.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/StringList.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/StringQueue.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/StringSet.ring",
		"libraries/dotnetlib/generated/System.Collections.Generic/StringStack.ring",
		"libraries/dotnetlib/generated/System.Collections.ObjectModel.ring",
		"libraries/dotnetlib/generated/System.Collections.ObjectModel/ObservableStringList.ring",
		"libraries/dotnetlib/generated/System.Diagnostics.ring",
		"libraries/dotnetlib/generated/System.Diagnostics/Stopwatch.ring",
		"libraries/dotnetlib/generated/System.IO.ring",
		"libraries/dotnetlib/generated/System.IO/Directory.ring",
		"libraries/dotnetlib/generated/System.IO/File.ring",
		"libraries/dotnetlib/generated/System.IO/Path.ring",
		"libraries/dotnetlib/generated/System.Net.Http.ring",
		"libraries/dotnetlib/generated/System.Net.Http/HttpClient.ring",
		"libraries/dotnetlib/generated/System.Text.ring",
		"libraries/dotnetlib/generated/System.Text/ASCIIEncoding.ring",
		"libraries/dotnetlib/generated/System.Text/Ascii.ring",
		"libraries/dotnetlib/generated/System.Text/CompositeFormat.ring",
		"libraries/dotnetlib/generated/System.Text/Decoder.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderExceptionFallback.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderExceptionFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderFallback.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderReplacementFallback.ring",
		"libraries/dotnetlib/generated/System.Text/DecoderReplacementFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/Encoder.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderExceptionFallback.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderExceptionFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderFallback.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderReplacementFallback.ring",
		"libraries/dotnetlib/generated/System.Text/EncoderReplacementFallbackBuffer.ring",
		"libraries/dotnetlib/generated/System.Text/Encoding.ring",
		"libraries/dotnetlib/generated/System.Text/EncodingInfo.ring",
		"libraries/dotnetlib/generated/System.Text/EncodingProvider.ring",
		"libraries/dotnetlib/generated/System.Text/Rune.ring",
		"libraries/dotnetlib/generated/System.Text/StringBuilder.ring",
		"libraries/dotnetlib/generated/System.Text/StringRuneEnumerator.ring",
		"libraries/dotnetlib/generated/System.Text/UTF32Encoding.ring",
		"libraries/dotnetlib/generated/System.Text/UTF7Encoding.ring",
		"libraries/dotnetlib/generated/System.Text/UTF8Encoding.ring",
		"libraries/dotnetlib/generated/System.Text/UnicodeEncoding.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/Application.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/Button.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/CheckBox.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/ControlCollection.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/Form.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/Label.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/ListBox.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/MessageBox.ring",
		"libraries/dotnetlib/generated/System.Windows.Forms/TextBox.ring",
		"libraries/dotnetlib/generated/System.ring",
		"libraries/dotnetlib/generated/System/Console.ring",
		"libraries/dotnetlib/generated/System/DateTime.ring",
		"libraries/dotnetlib/generated/System/Environment.ring",
		"libraries/dotnetlib/generated/System/Guid.ring",
		"libraries/dotnetlib/generated/System/Math.ring",
		"libraries/dotnetlib/generated/System/Random.ring",
		"libraries/dotnetlib/generated/System/TimeSpan.ring",
		"libraries/dotnetlib/globals.ring",
		"samples/UsingDotNet/test01_hello.ring",
		"samples/UsingDotNet/test02_natural.ring",
		"samples/UsingDotNet/test03_collections.ring",
		"samples/UsingDotNet/test04_callbacks.ring",
		"samples/UsingDotNet/test05_events.ring",
		"samples/UsingDotNet/test06_winforms_click.ring",
		"samples/UsingDotNet/test07_properties.ring",
		"tests/run.sh",
		"tests/test_foundation.ring",
		"tools/dotnetmanifest.ring",
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
		"bin/RingDotNet.Desktop.runtimeconfig.json",
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
