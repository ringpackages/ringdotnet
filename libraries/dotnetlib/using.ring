/*
	using { ... } : import .NET namespaces the way C# does, and start the runtime mode that the namespaces need.

	load "dotnet.ring"
	using {
		"System"
		"System.Text"
		"System.IO"
	}

	It does the same as dnImport("System") ... for each text. Anything that is not a text is an error.

	At the end of the block (braceEnd) it looks at the names and starts what the program needs, so that the program does not
	have to call dnUseDesktop(), dnUseWeb() or dnUseData() itself:

		System.Windows*, System.Drawing*     Windows Forms / WPF       (dnUseDesktop)
		Microsoft.AspNetCore*, RingDotNet.Web  ASP.NET Core + WebServer  (dnUseWeb)
		Microsoft.EntityFrameworkCore*, Microsoft.Data.Sqlite*, RingDotNet.Data   Entity Framework + RingDatabase (dnUseData)

	"RingDotNet.Web" and "RingDotNet.Data" are not .NET namespaces: they name the helper classes of this package
	(WebServer; RingDatabase, RingEntityDb, RingTypedDb) and only select the mode.
	Desktop and web together (in one block, or in blocks before the first .NET call) start the "all" mode.
	Put the using block before the first .NET call: the runtime can be started in one mode only.
*/

class UsingClass

	lDesktop = false		# a namespace of Windows Forms / WPF was used
	lWeb = false			# ASP.NET Core or the web helpers
	lData = false			# Entity Framework or the data helpers
	lDataLoaded = false

	func braceExprEval  dn_xValue
		if not isstring(dn_xValue)
			raise('DotNet Error: using { } expects namespace names as texts ("System.IO"), not a ' + type(dn_xValue))
		ok
		if startsWith(dn_xValue,"System.Windows") or startsWith(dn_xValue,"System.Drawing")
			lDesktop = true
		but startsWith(dn_xValue,"Microsoft.AspNetCore")
			lWeb = true
		but startsWith(dn_xValue,"Microsoft.EntityFrameworkCore") or startsWith(dn_xValue,"Microsoft.Data.Sqlite")
			lData = true
		ok
		if dn_xValue = "RingDotNet.Web"
			lWeb = true
			return
		but dn_xValue = "RingDotNet.Data"
			lData = true
			return
		ok
		dnImport(dn_xValue)

	# after the closing brace: start the runtime mode that the names asked for
	func braceEnd
		cWanted = ""
		if lDesktop and lWeb
			cWanted = "all"
		but lDesktop
			cWanted = "desktop"
		but lWeb
			cWanted = "web"
		ok
		if cWanted != "" and cWanted != cDotNetMode and cDotNetMode != "all"
			if cDotNetMode != ""
				raise('DotNet Error: this program needs the "' + cWanted + '" mode but the runtime was already started in the "' + cDotNetMode +
					'" mode. Put the namespaces of both Windows Forms/WPF and ASP.NET Core in the first using { } block, before any other .NET call.')
			ok
			switch cWanted
			on "desktop"
				dnUseDesktop()
			on "web"
				dnUseWeb()
			on "all"
				dnUseAll()
			off
		ok
		if lData and not lDataLoaded
			lDataLoaded = true
			dnUseData()
		ok

	func startsWith dn_cText, dn_cStart
		return left(dn_cText,len(dn_cStart)) = dn_cStart
