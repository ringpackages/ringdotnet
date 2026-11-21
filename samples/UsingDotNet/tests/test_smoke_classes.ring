# A smoke test over the classes of many namespaces: every public class that has a constructor without parameters can be created by the
# bridge, and the answer is a real object (a handle that is not 0). A class whose constructor refuses on this system (OpenSSL on Windows,
# for example) raises a PlatformNotSupportedException, which is fine; any other error, or a handle of 0, is a failure.
load "dotnet.ring"

func main
	aNamespaces = ["System.Collections","System.Collections.Generic","System.Collections.Specialized","System.Collections.Concurrent",
		"System.Collections.ObjectModel","System.Text","System.Text.Json","System.Text.Json.Nodes","System.Xml","System.Xml.Linq",
		"System.Data","System.Numerics","System.ComponentModel","System.IO","System.Globalization","System.Net.Mail",
		"System.Security.Cryptography","System.Diagnostics","System.Net","System.Text.RegularExpressions"]
	# classes that start something outside the program when they are made
	aSkip = ["System.Diagnostics.Process","System.IO.FileSystemWatcher","System.Net.HttpListener","System.Diagnostics.Stopwatch"]
	dnBuildIndexMap()
	nTried = 0
	aNull = []
	aErrors = []
	for cNamespace in aNamespaces
		dnImport(cNamespace)
		for aEntry in aDotNetClassIndex
			if aEntry[2] != cNamespace or find(aSkip,aEntry[1]) > 0
				loop
			ok
			aApi = ""
			try
				aApi = dnDescribe(aEntry[1])          # a few types of the list cannot be described on this system: they are left out
			catch
				loop
			done
			if not islist(aApi) or aApi[2] = 1
				loop
			ok
			lParameterless = False
			for aConstructor in aApi[3]
				if len(aConstructor) = 0
					lParameterless = True
				ok
			next
			if not lParameterless
				loop
			ok
			nTried++
			try
				if dnCreate(aEntry[1],[]) = 0
					aNull + aEntry[1]
				ok
			catch
				if substr(cCatchError,"PlatformNotSupportedException") = 0
					aErrors + (aEntry[1] + ": " + left(cCatchError,60))
				ok
			done
		next
	next
	dnAssert("many classes were tried (" + nTried + ")",nTried > 150,True)
	dnAssert("no class gave a handle of 0 " + joined(aNull),len(aNull),0)
	dnAssert("no class raised another error " + joined(aErrors),len(aErrors),0)
	dnTestSummary()

# the items of a list as one text (empty for an empty list)
func joined aList
	cText = ""
	for cItem in aList
		cText += cItem + "; "
	next
	return cText
