# Writes the API of every wrapped .NET class as JSON lines: ring dumpapi.ring <types file> <output file>
#   types file lines: <namespace> TAB <Ring class> TAB <.NET type name>
#   output lines:     <namespace> TAB <Ring class> TAB <JSON from the bridge>   (or an ERROR line)
# Run it with dumpapi.py, which also makes the types file.

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseAll()
dnUseData()

func main
	cTypes = sysargv[3]
	cOut = sysargv[4]
	aLines = str2list(read(cTypes))
	fp = fopen(cOut,"w")
	nDone = 0
	nFailed = 0
	for cLine in aLines
		if trim(cLine) = ""
			loop
		ok
		aParts = str2list(substr(cLine,char(9),nl))
		if len(aParts) < 3
			loop
		ok
		cJson = ""
		cLastError = ""
		for cType in typeCandidates(aParts[3])
			try
				cJson = dnRequest("apidoc",[cType])
				exit
			catch
				cLastError = cCatchError
			done
		next
		if cJson != ""
			fputs(fp,aParts[1] + char(9) + aParts[2] + char(9) + cJson + nl)
			nDone++
		else
			fputs(fp,aParts[1] + char(9) + aParts[2] + char(9) + "ERROR " + substr(cLastError,nl," ") + nl)
			nFailed++
		ok
	next
	fclose(fp)
	? "" + nDone + " types written, " + nFailed + " failed"

# the name as given, then with assemblies that hold types the manifest finds by namespace
func typeCandidates cType
	aList = [cType]
	if substr(cType,",") = 0
		for cAsm in ["Microsoft.EntityFrameworkCore.Relational","Microsoft.AspNetCore.Mvc.Core","Microsoft.AspNetCore.Components.Endpoints","Microsoft.AspNetCore.Mvc.RazorPages","Microsoft.AspNetCore.Http.Results","Microsoft.AspNetCore.Http.Abstractions","Microsoft.AspNetCore.Routing","Microsoft.AspNetCore.Components","Microsoft.AspNetCore.Mvc.ViewFeatures","Microsoft.AspNetCore.Mvc.Razor"]
			aList + (cType + ", " + cAsm)
		next
	ok
	return aList
