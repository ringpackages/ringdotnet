/*
	using { ... } : import .NET namespaces the way C# does.

	load "dotnet.ring"
	using {
		"System"
		"System.Text"
		"System.IO"
	}

	It does the same as dnImport("System") ... for each text. Anything that is not a text is an error.
	Call it after dnUseDesktop() / dnUseWeb() / dnUseData(), like dnImport().
*/

class UsingClass

	func braceExprEval  dn_xValue
		if not isstring(dn_xValue)
			raise('DotNet Error: using { } expects namespace names as texts ("System.IO"), not a ' + type(dn_xValue))
		ok
		dnImport(dn_xValue)
